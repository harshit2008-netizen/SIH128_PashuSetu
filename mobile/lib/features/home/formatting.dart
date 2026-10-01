import '../../l10n/app_localizations.dart';

/// Photo model probability as a whole percent, kept within 1-99: a model is
/// never certain, and "100%" would read as a diagnosis.
int photoPercent(num probability) => (probability * 100).round().clamp(1, 99);

/// "just now", "5 min ago", "2 hours ago", "3 days ago".
String timeAgo(AppLocalizations l10n, DateTime when, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(when.toLocal());
  if (diff.inMinutes < 1) return l10n.justNow;
  if (diff.inHours < 1) return l10n.minutesAgo(diff.inMinutes);
  if (diff.inDays < 1) return l10n.hoursAgo(diff.inHours);
  return l10n.daysAgo(diff.inDays);
}

/// Short date in the user's language, e.g. "12 Oct" / "12 अक्टू".
String shortDate(String isoDate, String language) {
  const months = {
    'en': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
    'hi': ['जन', 'फ़र', 'मार्च', 'अप्रै', 'मई', 'जून', 'जुला', 'अग', 'सित', 'अक्टू', 'नव', 'दिस'],
    'mr': ['जाने', 'फेब्रु', 'मार्च', 'एप्रि', 'मे', 'जून', 'जुलै', 'ऑग', 'सप्टें', 'ऑक्टो', 'नोव्हें', 'डिसें'],
  };
  final date = DateTime.parse(isoDate);
  return '${date.day} ${(months[language] ?? months['en']!)[date.month - 1]}';
}

String statusLabel(AppLocalizations l10n, String status) => switch (status) {
      'reported' => l10n.statusReported,
      'triaged' => l10n.statusTriaged,
      'vet_assigned' => l10n.statusVetAssigned,
      'sample_requested' => l10n.statusSampleRequested,
      'sample_collected' => l10n.statusSampleCollected,
      'lab_received' => l10n.statusLabReceived,
      'lab_result' => l10n.statusLabResult,
      'under_treatment' => l10n.statusUnderTreatment,
      'resolved' => l10n.statusResolved,
      'closed_ruled_out' => l10n.statusClosedRuledOut,
      _ => status,
    };

/// A timeline line: a status change, a follow-up report, or an SLA escalation
/// (the server writes "escalation:1" / "escalation:2", the app words it).
String timelineLabel(AppLocalizations l10n, Map<String, dynamic> event) => switch (event['note']) {
      'escalation:1' => l10n.escalatedToBlock,
      'escalation:2' => l10n.escalatedToDistrict,
      'Follow-up report' => event['note'] as String,
      _ => statusLabel(l10n, event['to_status'] as String),
    };
