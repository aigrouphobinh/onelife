# Security and Privacy

- Data minimization and offline-by-default; no account required for MVP.
- Never request broad accessibility, SMS, or notification-listener privileges merely to collect information.
- Store secrets in platform secure storage; never commit tokens or signing keys.
- Threat-model stolen devices, malicious imports, corrupted DB, unintended exports and unsafe backups.
- Validate MIME and size of imported files; protect against path traversal.
- Decide and test at-rest encryption strategy before storing sensitive documents; SQLite alone is not encryption.
- Require user confirmation for exports and deletion; support recovery where feasible.
- Never send notes to remote AI without explicit per-feature consent.
- Review Android/iOS privacy disclosures and store policies before release.

## Security release checklist
Dependency audit; secret scan; permission audit; secure backup test; privacy policy; incident response owner; vulnerability reporting process.
