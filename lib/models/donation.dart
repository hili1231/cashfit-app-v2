class Donation {
  final String donorId;
  final String
  recipientUserId; // The challenge participant receiving the donation
  final double amount;
  final DateTime date; // When the donation was made

  Donation({
    required this.donorId,
    required this.recipientUserId,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'donorId': donorId,
      'recipientUserId': recipientUserId,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  factory Donation.fromMap(Map<String, dynamic> map) {
    return Donation(
      donorId: map['donorId'] as String,
      recipientUserId: map['recipientUserId'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
    );
  }
}
