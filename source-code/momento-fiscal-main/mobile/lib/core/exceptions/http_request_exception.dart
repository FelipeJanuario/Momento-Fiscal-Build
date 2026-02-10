class HttpRequestException implements Exception {
  HttpRequestException(this.cause);

  String cause;
}
