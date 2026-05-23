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
    id: j['id'] as String,
    title: j['title'] as String,
    type: j['type'] as String,
    status: j['status'] as String,
    stepGoal: (j['step_goal'] as num).toInt(),
    entryFee: (j['entry_fee'] as num).toInt(),
    prizePool: (j['prize_pool'] as num).toInt(),
    startTime: DateTime.parse(j['start_time'] as String),
    endTime: DateTime.parse(j['end_time'] as String),
    sponsorName: j['sponsor_name'] as String?,
  );

  bool get isPaid => entryFee > 0;
  String get entryFeeInr => '₹${entryFee ~/ 100}';
  String get prizePoolInr => '₹${prizePool ~/ 100}';
}
