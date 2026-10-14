String publicationDateLabel(DateTime date) =>
    'Dipublikasikan: ${date.day}/${date.month}/${date.year}';

String localTimestampLabel(DateTime date) => date.toLocal().toString();
