import 'package:flutter_test/flutter_test.dart';
import 'package:stepup/shared/models/challenge.dart';
import 'package:stepup/shared/models/leaderboard_entry.dart';
import 'package:stepup/shared/models/wallet_transaction.dart';

void main() {
  group('Challenge', () {
    final json = {
      'id': 'c1',
      'title': '10k Steps Daily',
      'type': 'paid_pool',
      'status': 'active',
      'step_goal': 10000,
      'entry_fee': 5000,
      'prize_pool': 45000,
      'start_time': '2026-05-23T00:00:00.000Z',
      'end_time': '2026-05-23T23:59:59.000Z',
      'sponsor_name': null,
    };

    test('fromJson parses all fields', () {
      final c = Challenge.fromJson(json);
      expect(c.id, 'c1');
      expect(c.stepGoal, 10000);
      expect(c.entryFee, 5000);
      expect(c.prizePool, 45000);
      expect(c.activityType, 'steps');
    });

    test('isPaid is true when entryFee > 0', () {
      expect(Challenge.fromJson(json).isPaid, isTrue);
    });

    test('entryFeeInr converts paise to rupees', () {
      expect(Challenge.fromJson(json).entryFeeInr, '₹50');
    });

    test('prizePoolInr converts paise to rupees', () {
      expect(Challenge.fromJson(json).prizePoolInr, '₹450');
    });
  });

  group('LeaderboardEntry', () {
    final json = {
      'rank': 3,
      'steps': 12500,
      'user_id': 'u1',
      'name': 'Harsha',
      'city': 'Hyderabad',
    };

    test('fromJson parses all fields', () {
      final e = LeaderboardEntry.fromJson(json);
      expect(e.rank, 3);
      expect(e.steps, 12500);
      expect(e.userId, 'u1');
      expect(e.city, 'Hyderabad');
    });

    test('city defaults to empty string when null', () {
      final e = LeaderboardEntry.fromJson({...json, 'city': null});
      expect(e.city, '');
    });
  });

  group('WalletTransaction', () {
    final json = {
      'id': 't1',
      'type': 'credit',
      'description': 'Challenge winnings',
      'amount': 10000,
      'created_at': '2026-05-23T10:00:00.000Z',
    };

    test('fromJson parses all fields', () {
      final t = WalletTransaction.fromJson(json);
      expect(t.id, 't1');
      expect(t.amount, 10000);
    });

    test('isCredit is true for credit type', () {
      expect(WalletTransaction.fromJson(json).isCredit, isTrue);
    });

    test('isCredit is false for debit type', () {
      final t = WalletTransaction.fromJson({...json, 'type': 'debit'});
      expect(t.isCredit, isFalse);
    });

    test('amountInr shows + prefix for credit', () {
      expect(WalletTransaction.fromJson(json).amountInr, '+₹100');
    });

    test('amountInr shows - prefix for debit', () {
      final t = WalletTransaction.fromJson({...json, 'type': 'debit'});
      expect(t.amountInr, '-₹100');
    });
  });
}
