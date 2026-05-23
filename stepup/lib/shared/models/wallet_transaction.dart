class WalletTransaction {
  final String id, type, description;
  final int amount;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id, required this.type, required this.description,
    required this.amount, required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> j) => WalletTransaction(
    id: j['id'], type: j['type'], description: j['description'],
    amount: j['amount'], createdAt: DateTime.parse(j['created_at']),
  );

  bool get isCredit => type == 'credit';
  String get amountInr => '${isCredit ? '+' : '-'}₹${(amount / 100).toStringAsFixed(0)}';
}
