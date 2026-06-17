import 'package:flutter/material.dart';

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

const List<OnboardingPage> onboardingPages = [
  OnboardingPage(
    title: 'تتبع سيارتك',
    description:
        'تابع موقع مركبتك في الوقت الفعلي من أي مكان وفي أي وقت بدقة عالية عبر نظام GPS المتطور',
    icon: Icons.location_on_rounded,
    color: Color(0xFF1A237E),
  ),
  OnboardingPage(
    title: 'أمان وتنبيهات',
    description:
        'احصل على تنبيهات فورية عند تجاوز السرعة المحددة أو مغادرة المنطقة الجغرافية المحددة لحماية مركبتك',
    icon: Icons.shield_rounded,
    color: Color(0xFF00BCD4),
  ),
  OnboardingPage(
    title: 'إدارة وصيانة',
    description:
        'نظّم جدول صيانة مركباتك وتتبع تاريخ الخدمات وتكاليفها للحفاظ على سلامة مركبتك دائماً',
    icon: Icons.build_rounded,
    color: Color(0xFF4CAF50),
  ),
];
