# Privacy, retention, and deletion considerations

This repository does not establish a legal retention schedule. A real deployment must identify data owners, purpose, lawful basis, jurisdictions, recordkeeping obligations, litigation holds, and contractual requirements.

Design considerations:

- Separate client profile retention from immutable transaction and audit retention.
- Use deactivation or pseudonymization when deletion conflicts with required financial records.
- Keep audit metadata minimal and avoid copying sensitive request content.
- Define temporal-history retention and cleanup jobs.
- Apply lifecycle rules to protected audit storage.
- Document data-subject request handling without promising deletion that law or recordkeeping rules prohibit.
- Test backup expiration and restored-copy handling.
