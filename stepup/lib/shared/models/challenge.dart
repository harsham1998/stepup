class Challenge {
  final String id, title, type, status;
  final int stepGoal, entryFee, prizePool;
  final DateTime startTime, endTime;
  final String? sponsorName;

  const Challenge({
    required this.id, required this.title, required this.type,
    required this.status, required this.stepGoal, required this.entryFee,
    required this.prizePool, required this.startTime, required this.endTime,
    this.sponsorName,
  });

  factory Challenge.fromJson(Map<String, dynamic> j) => Challenge(
    id: j['id'], title: j['title'], type: j['type'], status: j['status'],
    stepGoal: j['step_goal'], entryFee: j['entry_fee'], prizePool: j['prize_pool'],
    startTime: DateTime.parse(j['start_time']),
    endTime: DateTime.parse(j['end_time']),
    sponsorName: j['sponsor_name'],
  );

  bool get isPaid => entryFee > 0;
  String get entryFeeInr => '₹${(entryFee / 100).toStringAsFixed(0)}';
  String get prizePoolInr => '₹${(prizePool / 100).toStringAsFixed(0)}';
}
