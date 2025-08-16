import 'dart:math';
import '../models/models.dart';

class InterestService {
  // 3% per month simple interest
  static const double monthlyRate = 0.03;

  static double monthsBetween(DateTime from, DateTime to) {
    final int days = to.difference(from).inDays;
    return days / 30.0; // approximate month length
  }

  static Map<String, double> computeTotals(List<Payment> payments, {DateTime? asOf}) {
    final DateTime today = asOf ?? DateTime.now();
    double principal = 0.0;
    double interest = 0.0;

    for (final p in payments) {
      principal += p.amount;
      final dt = DateTime.parse(p.paidAtIso);
      final m = monthsBetween(dt, today);
      final si = p.amount * monthlyRate * max(m, 0.0);
      interest += si;
    }

    final total = principal + interest;
    return {
      'principal': double.parse(principal.toStringAsFixed(2)),
      'interest': double.parse(interest.toStringAsFixed(2)),
      'total': double.parse(total.toStringAsFixed(2)),
    };
  }
}