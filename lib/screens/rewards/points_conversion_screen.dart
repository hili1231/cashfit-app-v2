import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

import '../../auth/login_screen.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../nav_screen.dart';
import '../../theme.dart';

class PointsConversionScreen extends StatefulWidget {
  const PointsConversionScreen({super.key});

  @override
  State<PointsConversionScreen> createState() => _PointsConversionScreenState();
}

class _PointsConversionScreenState extends State<PointsConversionScreen> {
  final TextEditingController _fitCoinsController = TextEditingController();
  final TextEditingController _recipientEmailController =
      TextEditingController();

  // ── Constants ────────────────────────────────────────────────────────────────
  static const double _conversionRate = 0.0002; // 5 000 FitCoins = \$1
  static const int _minConversion = 5_000; // Minimum to convert
  static const double _minWithdrawal = 5.0; // \$5 minimum withdraw

  // ── State ────────────────────────────────────────────────────────────────────
  double _cashValue = 0.0;
  bool _converting = false;
  bool _withdrawing = false;
  String? _payoutMethod; // 'paypal' | 'stripe'
  List<Map<String, dynamic>> _withdrawals = [];

  final Logger _log = Logger();

  @override
  void initState() {
    super.initState();
    _checkLoggedIn();
    _fitCoinsController.addListener(_recalcCashValue);
    _fetchWithdrawals();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  void _checkLoggedIn() {
    final userProv = context.read<UserProvider>();
    if (!userProv.isLoggedIn || userProv.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          AppTheme.createPageRoute(const LoginScreen()),
        );
      });
    }
  }

  void _recalcCashValue() {
    final coins = int.tryParse(_fitCoinsController.text) ?? 0;
    setState(() => _cashValue = coins * _conversionRate);
  }

  Future<void> _fetchWithdrawals() async {
    final userProv = context.read<UserProvider>();
    if (userProv.currentUser == null) return;
    try {
      final snap =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userProv.currentUser!.id)
              .collection('withdrawals')
              .orderBy('requestDate', descending: true)
              .limit(5)
              .get();

      setState(
        () =>
            _withdrawals =
                snap.docs.map((d) {
                  final data = d.data();
                  return {
                    'id': d.id,
                    'amount': data['amount'] as num,
                    'status': data['status'] as String,
                    'requestDate': (data['requestDate'] as Timestamp).toDate(),
                    'approvalDate':
                        data['approvalDate'] != null
                            ? (data['approvalDate'] as Timestamp).toDate()
                            : null,
                    'payoutMethod': data['payoutMethod'] as String,
                    'recipientEmail': data['recipientEmail'] as String,
                    'payoutBatchId': data['payoutBatchId'],
                  };
                }).toList(),
      );
    } catch (e) {
      _showSnack("Failed to load withdrawal requests: $e", isError: true);
      _log.e(e);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? cs.error : cs.primary,
        content: Text(
          msg,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isError ? cs.onError : cs.onPrimary,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ── Primary action button (consistent look) ─────────────────────────────────
  Widget _actionButton(String label, bool busy, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: busy ? null : onTap,
      child:
          busy
              ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.onPrimary,
                ),
              )
              : Text(label),
    );
  }

  // ── Convert FitCoins ────────────────────────────────────────────────────────
  Future<void> _convert() async {
    setState(() => _converting = true);
    final userProv = context.read<UserProvider>();
    final coins = int.tryParse(_fitCoinsController.text) ?? 0;

    try {
      if (coins < _minConversion) {
        throw Exception("Minimum conversion is $_minConversion FitCoins");
      }
      if (coins > (userProv.currentUser!.points ?? 0)) {
        throw Exception("Not enough FitCoins");
      }

      await AuthService.instance.updateUserFields(userProv.currentUser!.id, {
        'points': FieldValue.increment(-coins),
        'balance': FieldValue.increment(_cashValue),
      });

      _showSnack(
        "Converted $coins FitCoins to \$${_cashValue.toStringAsFixed(2)}",
      );
      _fitCoinsController.clear();
      _recalcCashValue();
      await userProv.loadUserData(FirebaseAuth.instance.currentUser!.uid);
    } catch (e) {
      _showSnack("Conversion failed: $e", isError: true);
      _log.e(e);
    } finally {
      if (mounted) setState(() => _converting = false);
    }
  }

  // ── Withdraw Modal ─────────────────────────────────────────────────────────
  Future<void> _withdraw() async {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              backgroundColor: cs.surfaceContainer,
              title: Text(
                "Withdraw Funds",
                style: txt.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: _payoutMethod,
                    isExpanded: true,
                    hint: Text(
                      "Select Payout Method",
                      style: txt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'paypal', child: Text('PayPal')),
                      DropdownMenuItem(value: 'stripe', child: Text('Stripe')),
                    ],
                    onChanged:
                        (val) => setStateDialog(() => _payoutMethod = val),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _recipientEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText:
                          _payoutMethod == 'paypal'
                              ? 'PayPal Email'
                              : 'Stripe Email',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: txt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    final email = _recipientEmailController.text.trim();
                    if (_payoutMethod == null) {
                      _showSnack('Choose a payout method', isError: true);
                      return;
                    }
                    if (!email.contains('@')) {
                      _showSnack('Invalid email', isError: true);
                      return;
                    }
                    Navigator.pop(ctx);
                    _submitWithdrawal(_payoutMethod!, email);
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );

    // reset dialog inputs
    _recipientEmailController.clear();
    _payoutMethod = null;
  }

  Future<void> _submitWithdrawal(String method, String email) async {
    setState(() => _withdrawing = true);
    final userProv = context.read<UserProvider>();

    try {
      final balance = userProv.currentUser!.balance ?? 0.0;
      if (balance < _minWithdrawal) {
        throw Exception(
          'Minimum withdrawal is \$${_minWithdrawal.toStringAsFixed(2)}',
        );
      }

      final pending =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userProv.currentUser!.id)
              .collection('withdrawals')
              .where('status', isEqualTo: 'pending')
              .get();
      if (pending.docs.isNotEmpty) {
        throw Exception('Existing pending withdrawal');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userProv.currentUser!.id)
          .collection('withdrawals')
          .add({
            'amount': balance,
            'status': 'pending',
            'requestDate': FieldValue.serverTimestamp(),
            'payoutMethod': method,
            'recipientEmail': email,
          });

      _showSnack('Withdrawal request submitted');
      await _fetchWithdrawals();
    } catch (e) {
      _showSnack('Withdrawal failed: $e', isError: true);
      _log.e(e);
    } finally {
      if (mounted) setState(() => _withdrawing = false);
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userProv = context.watch<UserProvider>();
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    if (userProv.isLoading ||
        !userProv.isLoggedIn ||
        userProv.currentUser == null) {
      return _busyScaffold(cs);
    }

    return Container(
      decoration: AppTheme.backgroundGradient(cs),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ────────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CONVERT FitCoins',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        color: cs.onSurface,
                        onPressed: () {
                          context
                              .findAncestorStateOfType<NavScreenState>()
                              ?.clearDetailScreen();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── FitCoin Wallet Card ──────────────────────────────────
                  _walletCard(
                    title: 'FitCoin Wallet',
                    subtitle: '${userProv.currentUser!.points ?? 0} FitCoins',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conversion rate · 5 000 FitCoins = \$1',
                          style: txt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _fitCoinsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'FitCoins to convert',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Cash value: \$${_cashValue.toStringAsFixed(2)}',
                          style: txt.bodyLarge?.copyWith(color: cs.onSurface),
                        ),
                        const SizedBox(height: 20),
                        _actionButton('Convert to Cash', _converting, _convert),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Cash Wallet Card ─────────────────────────────────────
                  _walletCard(
                    title: 'Cash Wallet',
                    subtitle:
                        '\$${(userProv.currentUser!.balance ?? 0).toStringAsFixed(2)}',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Minimum withdrawal · \$${_minWithdrawal.toStringAsFixed(2)}',
                          style: txt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _actionButton(
                          'Request Withdrawal',
                          _withdrawing,
                          _withdraw,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Recent Withdrawals ───────────────────────────────────
                  if (_withdrawals.isNotEmpty) ...[
                    Text(
                      'Recent withdrawals',
                      style: txt.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._withdrawals.map((w) => _withdrawalTile(w, txt, cs)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Reusable pieces ────────────────────────────────────────────────────────
  Widget _walletCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset('assets/images/fitcoin_icon.png', width: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: txt.titleLarge?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: txt.bodyLarge?.copyWith(color: cs.onSurface)),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  Widget _withdrawalTile(
    Map<String, dynamic> w,
    TextTheme txt,
    ColorScheme cs,
  ) {
    final statusColor =
        w['status'] == 'pending'
            ? cs.onSurfaceVariant
            : w['status'] == 'approved'
            ? cs.primary
            : cs.error;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '\$${(w['amount'] as num).toStringAsFixed(2)} · ${w['status'].toString().toUpperCase()} (${w['payoutMethod']})',
              style: txt.bodyMedium?.copyWith(color: statusColor),
            ),
          ),
          Text(
            '${w['requestDate'].day}/${w['requestDate'].month}/${w['requestDate'].year}',
            style: txt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _busyScaffold(ColorScheme cs) => Container(
    decoration: AppTheme.backgroundGradient(cs),
    child: const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(child: CircularProgressIndicator()),
    ),
  );
}
