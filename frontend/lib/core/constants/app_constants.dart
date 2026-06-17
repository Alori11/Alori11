class AppConstants {
  AppConstants._();

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String onboardingDoneKey = 'onboarding_done';
  static const String languageKey = 'app_language';
  static const String darkModeKey = 'dark_mode';

  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;

  static const int otpLength = 6;
  static const int otpResendSeconds = 60;

  static const int liveTrackingRefreshSeconds = 30;

  static const double defaultGeofenceRadius = 500.0;
  static const double defaultMapZoom = 15.0;

  static const List<String> carMakes = [
    'تويوتا',
    'هيونداي',
    'كيا',
    'نيسان',
    'هوندا',
    'فورد',
    'شيفروليه',
    'مرسيدس',
    'بي إم دبليو',
    'أودي',
    'لكزس',
    'إنفينيتي',
    'جيب',
    'لاند روفر',
    'ميتسوبيشي',
    'سوزوكي',
    'مازدا',
    'سوبارو',
    'فولكس فاجن',
    'بيجو',
    'رينو',
    'سيات',
    'سكودا',
    'فولفو',
    'جاكوار',
    'بورش',
    'فيراري',
    'لامبورغيني',
    'مازيراتي',
    'بنتلي',
    'رولز رويس',
    'أخرى',
  ];

  static const List<String> vehicleColors = [
    'أبيض',
    'أسود',
    'رمادي',
    'فضي',
    'أحمر',
    'أزرق',
    'أخضر',
    'أصفر',
    'برتقالي',
    'بني',
    'بيج',
    'ذهبي',
    'أرجواني',
  ];

  static const List<String> maintenanceTypes = [
    'تغيير الزيت',
    'تدوير الإطارات',
    'فحص الفرامل',
    'فلتر الهواء',
    'فحص البطارية',
    'صيانة عامة',
    'تغيير إطار',
    'فلتر الوقود',
    'شمعات الإشعال',
    'سائل التبريد',
    'أخرى',
  ];
}
