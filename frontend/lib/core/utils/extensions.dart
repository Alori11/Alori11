import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Cairo'),
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

extension DateTimeExtensions on DateTime {
  String toArabicDate() {
    final formatter = DateFormat('d MMMM yyyy', 'ar');
    return formatter.format(this);
  }

  String toArabicDateTime() {
    final formatter = DateFormat('d MMMM yyyy - hh:mm a', 'ar');
    return formatter.format(this);
  }

  String toTimeAgo() {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inSeconds < 60) {
      return 'منذ ${diff.inSeconds} ثانية';
    } else if (diff.inMinutes < 60) {
      return 'منذ ${diff.inMinutes} دقيقة';
    } else if (diff.inHours < 24) {
      return 'منذ ${diff.inHours} ساعة';
    } else if (diff.inDays < 30) {
      return 'منذ ${diff.inDays} يوم';
    } else {
      return toArabicDate();
    }
  }

  String toShortDate() {
    return DateFormat('dd/MM/yyyy').format(this);
  }

  String toShortTime() {
    return DateFormat('hh:mm a', 'ar').format(this);
  }

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
}

extension StringExtensions on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  bool get isValidEmail {
    return RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
        .hasMatch(this);
  }

  String normalizePhone() {
    final cleaned = replaceAll(' ', '').replaceAll('-', '');
    if (cleaned.startsWith('00966')) {
      return '+966${cleaned.substring(5)}';
    } else if (cleaned.startsWith('966')) {
      return '+$cleaned';
    } else if (cleaned.startsWith('05')) {
      return '+966${cleaned.substring(1)}';
    }
    return cleaned;
  }
}

extension DoubleExtensions on double {
  String toKmString() => '${toStringAsFixed(1)} كم';
  String toSpeedString() => '${toStringAsFixed(0)} كم/س';
}

extension DurationExtensions on int {
  String toArabicDuration() {
    if (this < 60) {
      return '$this دقيقة';
    }
    final hours = this ~/ 60;
    final mins = this % 60;
    if (mins == 0) return '$hours ساعة';
    return '$hours ساعة و$mins دقيقة';
  }
}
