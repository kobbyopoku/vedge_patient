import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// SECURITY P0 (Phase F) — allowlist wrapper around `url_launcher`.
///
/// We only allow a tiny set of schemes:
/// * `https://` — clinical content (Paystack checkout, Daily.co rooms, our
///   own legal pages, Google Maps directions).
/// * `tel:`     — critical-result call-clinician CTA (spec §6.10).
/// * `mailto:`  — get-help email.
/// * `vedge://` — our own deep links (e.g. payment-return).
///
/// Anything else is refused. This stops a compromised or untrusted backend
/// payload from punching the user out to `intent://`, `javascript:`, `file://`,
/// `app://` etc. Returns false on a refused / failed launch; the caller is
/// responsible for surfacing a snackbar.
const _allowedSchemes = {'https', 'tel', 'mailto', 'vedge'};

/// Decide whether a URL is safe to hand to `url_launcher`. Pure function so
/// it's unit-testable.
bool isUrlAllowed(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  if (scheme.isEmpty) return false;
  if (!_allowedSchemes.contains(scheme)) return false;
  // Defensive: `https` must have a non-empty host.
  if (scheme == 'https' && (uri.host.isEmpty)) return false;
  return true;
}

/// Launches [uri] iff it passes the allowlist. Returns true on success.
Future<bool> launchSafe(
  Uri uri, {
  LaunchMode mode = LaunchMode.externalApplication,
}) async {
  if (!isUrlAllowed(uri)) {
    debugPrint('[vedge-security] launch refused for scheme=${uri.scheme}');
    return false;
  }
  try {
    return await launchUrl(uri, mode: mode);
  } catch (e) {
    debugPrint('[vedge-security] launch failed: $e');
    return false;
  }
}

/// String overload for the common case.
Future<bool> launchSafeString(
  String url, {
  LaunchMode mode = LaunchMode.externalApplication,
}) {
  final parsed = Uri.tryParse(url);
  if (parsed == null) return Future.value(false);
  return launchSafe(parsed, mode: mode);
}
