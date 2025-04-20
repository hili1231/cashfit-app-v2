const { defineSecret } = require("firebase-functions/params");
const functions = require("firebase-functions/v2");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const paypal = require("@paypal/payouts-sdk");
const Stripe = require("stripe");

admin.initializeApp();

// 🔐 Define Secrets
const PAYPAL_CLIENT_ID = defineSecret("PAYPAL_CLIENT_ID");
const PAYPAL_CLIENT_SECRET = defineSecret("PAYPAL_CLIENT_SECRET");
const STRIPE_SECRET = defineSecret("STRIPE_SECRET");

// 🔔 Callable FCM Notification
exports.sendNotification = functions.https.onCall({
  region: "us-central1",
  secrets: [],
}, async (data, context) => {
  const { token, title, body, type, postId, userId } = data;

  if (!token || !title || !body) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing required fields: token, title, and body are required."
    );
  }

  const message = {
    token,
    notification: { title, body },
    data: {
      type: type || "",
      postId: postId || "",
      userId: userId || "",
    },
  };

  try {
    await admin.messaging().send(message);
    return { success: true };
  } catch (error) {
    throw new functions.https.HttpsError("internal", "Failed to send notification", error);
  }
});

// 🔁 Firestore Trigger: Payout Processor
exports.processPayout = onDocumentUpdated(
  {
    document: "users/{userId}/withdrawals/{withdrawalId}",
    region: "us-central1",
    secrets: [PAYPAL_CLIENT_ID, PAYPAL_CLIENT_SECRET, STRIPE_SECRET],
  },
  async (event) => {
    const { userId, withdrawalId } = event.params;
    const data = event.data.after.data();
    const prev = event.data.before.data();
    const db = admin.firestore();
    const userRef = db.collection("users").doc(userId);
    const userDoc = await userRef.get();
    const fcmToken = userDoc.data()?.fcmToken;

    const paypalClientId = PAYPAL_CLIENT_ID.value();
    const paypalClientSecret = PAYPAL_CLIENT_SECRET.value();
    const stripeSecret = STRIPE_SECRET.value();

    const paypalEnv = new paypal.core.SandboxEnvironment(paypalClientId, paypalClientSecret);
    const paypalClient = new paypal.core.PayPalHttpClient(paypalEnv);
    const stripe = new Stripe(stripeSecret, { apiVersion: "2020-08-27" });

    if (prev.status !== data.status && fcmToken) {
      let title = "";
      let bodyMsg = "";

      if (data.status === "pending") {
        title = "Withdrawal Request Submitted";
        bodyMsg = `Your request to withdraw $${data.amount.toFixed(2)} via ${
          data.payoutMethod === "paypal" ? "PayPal" : "Stripe"
        } is pending approval.`;
      } else if (data.status === "approved") {
        title = "Withdrawal Request Approved";
        bodyMsg = `Your request to withdraw $${data.amount.toFixed(2)} via ${
          data.payoutMethod === "paypal" ? "PayPal" : "Stripe"
        } has been approved!`;
      } else if (data.status === "rejected") {
        title = "Withdrawal Request Rejected";
        bodyMsg = `Your request to withdraw $${data.amount.toFixed(2)} via ${
          data.payoutMethod === "paypal" ? "PayPal" : "Stripe"
        } was rejected.`;
      }

      try {
        await admin.messaging().send({
          token: fcmToken,
          notification: { title, body: bodyMsg },
          data: { type: "withdrawal_status", userId },
        });
        console.log(`Notified ${userId}: ${title}`);
      } catch (err) {
        console.error(`Notify failed for ${userId}:`, err);
      }
    }

    if (
      data.status !== "approved" ||
      prev.status === "approved" ||
      data.payoutBatchId
    ) {
      return null;
    }

    const amount = data.amount;
    const method = data.payoutMethod;
    const recipient = data.recipientEmail;
    const withdrawRef = userRef.collection("withdrawals").doc(withdrawalId);

    try {
      let payoutBatchId = "";

      if (method === "paypal") {
        const req = new paypal.payouts.PayoutsPostRequest();
        req.requestBody({
          sender_batch_header: {
            sender_batch_id: `PAYOUT-${Date.now()}`,
            email_subject: "You have a payout from CashFit!",
          },
          items: [
            {
              recipient_type: "EMAIL",
              amount: {
                value: amount.toString(),
                currency: "USD",
              },
              receiver: recipient,
              note: "Payout from CashFit",
            },
          ],
        });

        const resp = await paypalClient.execute(req);
        payoutBatchId = resp.result.batch_header.payout_batch_id;
      } else if (method === "stripe") {
        const payout = await stripe.payouts.create(
          {
            amount: Math.round(amount * 100),
            currency: "usd",
            destination: "external_account",
            description: "Payout from CashFit",
          },
          { stripeAccount: "CONNECTED_ACCOUNT_ID" }
        );
        payoutBatchId = payout.id;
      } else {
        throw new Error("Invalid payout method");
      }

      await withdrawRef.update({ payoutBatchId });
      await userRef.update({
        balance: 0.0,
        points: admin.firestore.FieldValue.increment(-100),
      });

      console.log(`Processed payout ${payoutBatchId}`);

      if (fcmToken) {
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: "Payout Processed",
            body: `Your withdrawal of $${amount.toFixed(2)} has been processed via ${
              method === "paypal" ? "PayPal" : "Stripe"
            }!`,
          },
          data: { type: "withdrawal_processed", userId },
        });
        console.log(`Success notice sent to ${userId}`);
      }
    } catch (err) {
      await withdrawRef.update({ status: "rejected" });
      console.error("Payout error:", err);

      if (fcmToken) {
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: "Payout Failed",
            body: `Your $${amount.toFixed(2)} withdrawal failed. Please contact support.`,
          },
          data: { type: "withdrawal_failed", userId },
        });
        console.log(`Failure notice sent to ${userId}`);
      }
    }

    return null;
  }
);
