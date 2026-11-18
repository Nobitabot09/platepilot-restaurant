# Pet Shanti staff authentication migration — STAGING ONLY

Status: **NOT DEPLOYED, NOT ENROLLED, NOT READY TO MERGE**. Work lives only on `feature/staff-totp-safe-migration`; Cloudflare Pages uses direct uploads, so do not upload this branch's Worker.

## Current production audit
- The public root page includes staff markup and links to Kitchen, Admin and Counter.
- Role-specific passwords are compared server-side against `ADMIN_PASSWORD`, `KITCHEN_PASSWORD`, optional `COUNTER_PASSWORD`.
- Current session cookie is signed and HttpOnly, 8-hour expiry, `Path=/api`; backend enforces role checks.
- No per-person identity or TOTP enrollment exists yet. Kitchen and manager are shared role passwords; counter credential is optional.
- Existing D1 orders, order_items, order_events, payments, feedback, menu and settings must remain untouched.

## Proposed architecture
1. `/` and `/?table=N` serve a customer-only HTML bundle with NO staff views, login controls, or staff JavaScript. Keep all QR and ordering behavior.
2. `/staff` serves a separate staff-only HTML bundle. A role-specific username + password starts login; successful TOTP challenge completes login. Only authenticated staff receive role-appropriate UI, while APIs enforce authorization independently.
3. Add individual staff accounts with roles `manager`, `kitchen`, `counter`. Do not use password alone to infer identity; prevent shared credentials. Use slow salted password hashing (e.g. PBKDF2 with calibrated iterations or an external managed identity provider). Do not commit secrets.
4. Create server-side sessions with random opaque identifiers stored as hashes in D1; `HttpOnly; Secure; SameSite=Strict; Path=/api`, rotation after MFA, inactivity and absolute expiry, logout revocation. Reject legacy `pp_session` only **after** migration succeeds.
5. TOTP uses RFC 6238 SHA-1, 6 digits, 30-second step, ±1 step tolerance. Persist last accepted counter and atomically enforce one-time use. Encrypt TOTP secrets at rest using a separately managed Cloudflare secret and authenticated encryption. Never expose secret after enrollment.
6. Pending enrollment: require manager identity proof, show QR and manual key once, require valid first code before activating. Use separate short-lived, single-purpose enrollment tokens and prevent CSRF. Require manager reauthentication to enroll/revoke others.
7. Recovery: issue 10 random single-use recovery codes per person, store only peppered hashes, show once and confirm backup saved. Recovery codes replace only TOTP, not password. Record recovery use and notify manager. Two-manager or documented owner-controlled recovery for lost device; never rely on developer receiving OTPs.
8. Apply rate limits to password, TOTP, recovery, and enrollment endpoints by account and IP; generic login errors; account lockouts with safe admin recovery; structured security audit events without credentials or OTP.
9. Manager and counter privileges must remain distinct; kitchen cannot access payments or admin. Explicitly configure `COUNTER_PASSWORD` or create the new counter account before retiring legacy auth.
10. Protect all mutations with CSRF checks and server-side role checks. Restrict account creation, password reset, enrollment, recovery and role changes to authorized manager workflows.
11. Do not change the production database during preparation. Create a **separate test D1 database** for schema and integration tests. Back up production D1 before any approved migration. Migration must be additive, idempotent, and reversible before retiring old auth.

## Suggested additive schema (not executed)
```sql
CREATE TABLE staff_accounts (
 id TEXT PRIMARY KEY, username TEXT NOT NULL UNIQUE,
 role TEXT NOT NULL CHECK(role IN ('manager','kitchen','counter')),
 password_salt TEXT NOT NULL, password_hash TEXT NOT NULL,
 totp_ciphertext TEXT, totp_iv TEXT, totp_last_counter INTEGER NOT NULL DEFAULT -1,
 mfa_enrolled_at TEXT, disabled INTEGER NOT NULL DEFAULT 0,
 created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE staff_recovery_codes (
 account_id TEXT NOT NULL REFERENCES staff_accounts(id),
 code_hash TEXT NOT NULL UNIQUE, used_at TEXT,
 PRIMARY KEY(account_id,code_hash)
);
CREATE TABLE staff_sessions (
 token_hash TEXT PRIMARY KEY, account_id TEXT NOT NULL REFERENCES staff_accounts(id),
 created_at INTEGER NOT NULL, last_seen_at INTEGER NOT NULL,
 expires_at INTEGER NOT NULL, revoked_at INTEGER
);
CREATE TABLE staff_auth_events (
 id INTEGER PRIMARY KEY AUTOINCREMENT, account_id TEXT,
 action TEXT NOT NULL, created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
```

## Rollout gates — must all pass before deployment
- [ ] Owner confirms staff roster, usernames, authorized roles, recovery custodians and manager approval policy.
- [ ] Owner chooses authenticator enrollment procedure, backup/recovery storage and lost-device process.
- [ ] Implement server routes, separate HTML bundles, encrypted TOTP, password KDF, atomic replay prevention and audit.
- [ ] Unit-test RFC 6238 vectors, clock skew, replay, wrong OTP, expired enrollment, one-time recovery, rate limits.
- [ ] Integration-test each role, cross-role 403, QR ordering, kitchen transitions, payments, receipts, analytics, logout.
- [ ] Confirm customer bundle contains no staff UI or privileged code; direct access to APIs remains denied.
- [ ] Create test D1 and run tests without modifying production data.
- [ ] Back up production D1; provision staff accounts; enroll every active role and validate recovery.
- [ ] Arrange a maintenance window, explicit owner go-ahead, staged release and rollback.
- [ ] Only then deploy the new worker and disable legacy password-only authentication.

## Draft code
`security/totp.js` implements isolated TOTP and recovery primitives, **not integrated into the live Worker**. It is not an authentication system by itself.
