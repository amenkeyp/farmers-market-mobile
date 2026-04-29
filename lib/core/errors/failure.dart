/// Domain-level error representation. Repositories translate Dio/Hive
/// exceptions into [Failure] so the presentation layer never depends on
/// transport errors.
class Failure implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, List<String>>? validation;
  final bool offline;

  const Failure(
    this.message, {
    this.statusCode,
    this.validation,
    this.offline = false,
  });

  factory Failure.offline([String? message]) => Failure(
        message ?? 'Vous êtes hors ligne. L’action sera synchronisée.',
        offline: true,
      );

  factory Failure.unknown([String? message]) =>
      Failure(message ?? 'Une erreur inattendue est survenue.');

  @override
  String toString() => 'Failure($statusCode): $message';
}
