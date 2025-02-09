import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:major_project/widgets/journey_widget/journey_model.dart';

class StatisticsService {
  final FirebaseFirestore _firestore;

  StatisticsService(this._firestore);

  Future<Map<String, dynamic>> getDailyStatistics(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final querySnapshot = await _firestore
        .collection('journey_history')
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThan: endOfDay)
        .get();

    double totalFare = 0;
    double totalDistance = 0;
    int completedJourneys = 0;
    int activeJourneys = 0;

    for (var doc in querySnapshot.docs) {
      final journey = Journey.fromMap(doc.data());
      if (journey.status == 'completed') {
        totalFare += journey.fare ?? 0;
        totalDistance += journey.distance ?? 0;
        completedJourneys++;
      } else {
        activeJourneys++;
      }
    }

    return {
      'totalFare': totalFare,
      'totalDistance': totalDistance,
      'completedJourneys': completedJourneys,
      'activeJourneys': activeJourneys,
      'totalJourneys': querySnapshot.docs.length,
    };
  }

  Future<Map<String, dynamic>> getMonthlyReport(DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 1);

    final querySnapshot = await _firestore
        .collection('journey_history')
        .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
        .where('timestamp', isLessThan: endOfMonth)
        .get();

    Map<int, double> dailyFares = {};
    double totalMonthlyFare = 0;
    double totalMonthlyDistance = 0;
    int totalJourneys = 0;

    for (var doc in querySnapshot.docs) {
      final journey = Journey.fromMap(doc.data());
      if (journey.status == 'completed') {
        final day = journey.timestamp.day;
        dailyFares[day] = (dailyFares[day] ?? 0) + (journey.fare ?? 0);
        totalMonthlyFare += journey.fare ?? 0;
        totalMonthlyDistance += journey.distance ?? 0;
        totalJourneys++;
      }
    }

    return {
      'dailyFares': dailyFares,
      'totalMonthlyFare': totalMonthlyFare,
      'totalMonthlyDistance': totalMonthlyDistance,
      'totalJourneys': totalJourneys,
      'averageDailyFare': totalMonthlyFare / dailyFares.length,
    };
  }
}