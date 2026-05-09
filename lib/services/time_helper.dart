import 'package:intl/intl.dart';

class TimeHelper {
  static String format(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inMinutes < 1) return 'zojuist';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min geleden';
    if (diff.inHours < 24) return '${diff.inHours} uur geleden';
    if (diff.inDays < 7) return '${diff.inDays} dagen geleden';
    
    return DateFormat('d MMM').format(dateTime);
  }
}