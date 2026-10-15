import 'package:content_db/content_db.dart';

/// Where "Report a mistake" sends its message (spec section 3.6).
class ReportTarget {
  const ReportTarget({this.whatsappNumber, this.email});

  /// Digits only, with the country code, as WhatsApp links need.
  final String? whatsappNumber;
  final String? email;

  /// From the church profile: its WhatsApp number, else its phone; and its email. Null
  /// when the church has none of these, which hides the menu item.
  static ReportTarget? of(ChurchProfile? church) {
    if (church == null) return null;
    final digits = (church.whatsapp ?? church.phone)?.replaceAll(
      RegExp(r'\D'),
      '',
    );
    final number = digits == null || digits.isEmpty ? null : digits;
    if (number == null && church.email == null) return null;
    return ReportTarget(whatsappNumber: number, email: church.email);
  }

  /// Opens a WhatsApp chat with [message] typed in.
  Uri? whatsappUri(String message) => whatsappNumber == null
      ? null
      : Uri.parse(
          'whatsapp://send?phone=$whatsappNumber'
          '&text=${Uri.encodeComponent(message)}',
        );

  /// Opens a new email with [subject] and [message].
  Uri? emailUri(String subject, String message) => email == null
      ? null
      : Uri(
          scheme: 'mailto',
          path: email,
          query:
              'subject=${Uri.encodeComponent(subject)}'
              '&body=${Uri.encodeComponent(message)}',
        );
}
