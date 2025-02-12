import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class RevenueTracker {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final String _revenuePath = 'daily_revenue';
  
  // Get today's date as YYYY-MM-DD
  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  // Initialize daily revenue record
  Future<void> initializeDailyRevenue() async {
    try {
      final ref = _database.ref('$_revenuePath/$_todayKey');
      final snapshot = await ref.get();
      
      if (!snapshot.exists) {
        await ref.set({
          'total': 0.0,
          'last_updated': ServerValue.timestamp,
        });
      }
    } catch (e) {
      debugPrint('Error initializing daily revenue: $e');
    }
  }

  // Add new fare to today's revenue using update method instead of transaction
  Future<void> addRevenue(double fare) async {
    try {
      final ref = _database.ref('$_revenuePath/$_todayKey');
      final snapshot = await ref.get();
      
      if (snapshot.exists) {
        final currentData = snapshot.value as Map;
        final currentTotal = (currentData['total'] as num?)?.toDouble() ?? 0.0;
        await ref.update({
          'total': currentTotal + fare,
          'last_updated': ServerValue.timestamp,
        });
      } else {
        await ref.set({
          'total': fare,
          'last_updated': ServerValue.timestamp,
        });
      }
    } catch (e) {
      debugPrint('Error adding revenue: $e');
    }
  }

  // Get stream of today's revenue
  Stream<double> getTodayRevenueStream() {
    return _database
        .ref('$_revenuePath/$_todayKey/total')
        .onValue
        .map((event) => (event.snapshot.value as num?)?.toDouble() ?? 0.0);
  }

  // Get historical revenue for a specific date
  Future<double> getHistoricalRevenue(DateTime date) async {
    try {
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final snapshot = await _database.ref('$_revenuePath/$dateKey/total').get();
      return (snapshot.value as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      debugPrint('Error getting historical revenue: $e');
      return 0.0;
    }
  }
}