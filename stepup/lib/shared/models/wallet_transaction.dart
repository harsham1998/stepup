class WalletTransaction {
  final String id, type, description;
  final int amount;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id, required this.type, required this.description,
    required this.amount, required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> j) => WalletTransaction(
    id: j['id'] as String,
    type: j['type'] as String,
    description: j['description'] as String,
    amount: (j['amount'] as num).toInt(),
    createdAt: DateTime.parse(j['created_at'] as String),
  );

  bool get isCredit => type == 'credit';
  String get amountInr => '${isCredit ? '+' : '-'}₹${amount ~/ 100}';
}
