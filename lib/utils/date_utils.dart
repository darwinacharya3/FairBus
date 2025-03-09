import 'package:intl/intl.dart';

class CustomDateUtils {
  // Get today's date in YYYY-MM-DD format
  static String getTodayFormattedDate() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM-dd').format(now);
  }
  
  // Parse date string to DateTime
  static DateTime? parseDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) {
      return null;
    }
    
    try {
      // Try parsing formats like "2025-3-9 12:50:48"
      final parts = dateTimeStr.split(' ');
      if (parts.length >= 2) {
        final dateParts = parts[0].split('-');
        final timeParts = parts[1].split(':');
        
        if (dateParts.length >= 3 && timeParts.length >= 3) {
          final year = int.tryParse(dateParts[0]) ?? DateTime.now().year;
          final month = int.tryParse(dateParts[1]) ?? 1;
          final day = int.tryParse(dateParts[2]) ?? 1;
          
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          final second = int.tryParse(timeParts[2]) ?? 0;
          
          return DateTime(year, month, day, hour, minute, second);
        }
      }
      
      // Fallback to standard date parser
      return DateTime.parse(dateTimeStr);
    } catch (e) {
      print('Error parsing date: $e');
      return null;
    }
  }
  
  // Format DateTime to string
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }
  
  // Check if a date string is today
  static bool isToday(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return false;
    
    try {
      final date = parseDateTime(dateStr);
      if (date == null) return false;
      
      final now = DateTime.now();
      return date.year == now.year && 
             date.month == now.month && 
             date.day == now.day;
    } catch (e) {
      return false;
    }
  }
}








// class CustomDateUtils {
//   static String getTodayFormattedDate() {
//     final now = DateTime.now();
//     return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
//   }
// }