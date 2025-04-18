const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendNotification = functions.https.onCall(async (data, context) => {
  const {token, title, body, type, postId, userId} = data;

  if (!token || !title || !body) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required fields: token, title, and body are required.",
    );
  }

  const message = {
    token: token,
    notification: {
      title: title,
      body: body,
    },
    data: {
      type: type || "",
      postId: postId || "",
      userId: userId || "",
    },
  };

  try {
    await admin.messaging().send(message);
    return {success: true};
  } catch (error) {
    throw new functions.https.HttpsError(
        "internal",
        "Failed to send notification",
        error,
    );
  }
});
