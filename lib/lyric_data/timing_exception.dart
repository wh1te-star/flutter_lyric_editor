class TimingException implements Exception {
  final String message;
  TimingException(this.message);

  @override
  String toString() => 'TimingException: $message';
}
