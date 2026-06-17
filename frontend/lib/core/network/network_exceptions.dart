class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  const NetworkException({required this.message, this.statusCode});

  @override
  String toString() => 'NetworkException: $message (status: $statusCode)';
}

class UnauthorizedException extends NetworkException {
  const UnauthorizedException()
      : super(message: 'غير مصرح لك بالوصول', statusCode: 401);
}

class ForbiddenException extends NetworkException {
  const ForbiddenException()
      : super(message: 'ليس لديك صلاحية للوصول', statusCode: 403);
}

class NotFoundException extends NetworkException {
  const NotFoundException({String message = 'لم يتم العثور على المورد'})
      : super(message: message, statusCode: 404);
}

class ServerException extends NetworkException {
  const ServerException({String message = 'خطأ في الخادم، يرجى المحاولة لاحقاً'})
      : super(message: message, statusCode: 500);
}

class ConnectionException extends NetworkException {
  const ConnectionException()
      : super(message: 'تعذّر الاتصال بالإنترنت', statusCode: null);
}

class TimeoutException extends NetworkException {
  const TimeoutException()
      : super(message: 'انتهت مهلة الطلب، يرجى المحاولة مجدداً', statusCode: null);
}

class ValidationException extends NetworkException {
  final Map<String, dynamic>? errors;

  const ValidationException({
    String message = 'بيانات غير صحيحة',
    this.errors,
  }) : super(message: message, statusCode: 422);
}
