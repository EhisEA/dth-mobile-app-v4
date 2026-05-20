/// Response root from `POST /support/web-session`.
class SupportWebSession {
  const SupportWebSession({required this.url});

  final String url;

  factory SupportWebSession.fromResponseRoot(Map<String, dynamic> root) {
    final raw = root["url"];
    final url = raw is String ? raw.trim() : "";
    return SupportWebSession(url: url);
  }
}
