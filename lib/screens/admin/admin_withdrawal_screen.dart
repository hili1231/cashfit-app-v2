import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminWithdrawalsScreen extends StatefulWidget {
  const AdminWithdrawalsScreen({super.key});

  @override
  State<AdminWithdrawalsScreen> createState() => _AdminWithdrawalsScreenState();
}

class _AdminWithdrawalsScreenState extends State<AdminWithdrawalsScreen> {
  bool isLoading = false;

  Future<List<Map<String, dynamic>>> _fetchPendingWithdrawals() async {
    List<Map<String, dynamic>> requests = [];

    // Fetch all users
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();

    for (var userDoc in usersSnapshot.docs) {
      final userId = userDoc.id;
      final userEmail = userDoc['email'] ?? 'Unknown';

      // Fetch pending withdrawals for this user
      final withdrawalsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('withdrawals')
          .where('status', isEqualTo: 'pending')
          .orderBy('requestDate', descending: true)
          .get();

      for (var withdrawalDoc in withdrawalsSnapshot.docs) {
        requests.add({
          'userId': userId,
          'userEmail': userEmail,
          'withdrawalId': withdrawalDoc.id,
          'amount': withdrawalDoc['amount'],
          'payoutMethod': withdrawalDoc['payoutMethod'],
          'recipientEmail': withdrawalDoc['recipientEmail'],
          'requestDate': (withdrawalDoc['requestDate'] as Timestamp).toDate(),
        });
      }
    }

    return requests;
  }

  Future<void> _refreshWithdrawals() async {
    setState(() {});
  }

  Future<void> _approveWithdrawal(String userId, String withdrawalId) async {
    setState(() {
      isLoading = true;
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('withdrawals')
          .doc(withdrawalId)
          .update({
        'status': 'approved',
        'approvalDate': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.primary,
          content: Text(
            "Withdrawal approved successfully!",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      // Refresh the list
      await _refreshWithdrawals();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.error,
          content: Text(
            "Failed to approve withdrawal: $e",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onError,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _rejectWithdrawal(String userId, String withdrawalId) async {
    setState(() {
      isLoading = true;
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('withdrawals')
          .doc(withdrawalId)
          .update({
        'status': 'rejected',
        'approvalDate': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.primary,
          content: Text(
            "Withdrawal rejected successfully!",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      // Refresh the list
      await _refreshWithdrawals();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.error,
          content: Text(
            "Failed to reject withdrawal: $e",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onError,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 2,
        centerTitle: true,
        title: Text(
          "Admin - Withdrawal Requests",
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchPendingWithdrawals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            );
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return Center(
              child: Text(
                "No pending withdrawal requests",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                elevation: 1,
                color: colorScheme.surfaceContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "User: ${request['userEmail']}",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Amount: \$${request['amount'].toStringAsFixed(2)}",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        "Method: ${request['payoutMethod'] == 'paypal' ? 'PayPal' : 'Stripe'}",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        "Recipient: ${request['recipientEmail']}",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        "Requested: ${request['requestDate'].day}/${request['requestDate'].month}/${request['requestDate'].year}",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                            ),
                            onPressed: () => _approveWithdrawal(request['userId'], request['withdrawalId']),
                            child: const Text("Approve"),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: colorScheme.error),
                              foregroundColor: colorScheme.error,
                            ),
                            onPressed: () => _rejectWithdrawal(request['userId'], request['withdrawalId']),
                            child: const Text("Reject"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}