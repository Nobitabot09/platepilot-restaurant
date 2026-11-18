# Pet Shanti standalone mockup upgrades

**Scope:** Pet Shanti only, not multi-tenant SaaS. Keep customer ordering and staff operations working independently of the new authentication prototype.

## Implemented on this branch
- Kitchen cards show elapsed minutes since order creation, refreshed with the existing kitchen polling interval. Orders over 20 minutes show an attention indicator. This is a demo threshold, not a promised preparation SLA.
- Existing database, orders, receipts, payments, roles and production deployment unchanged.
- Worker and embedded script syntax checked; browser and integration tests outstanding.

## Next implementation batches
1. **Service:** customer water/help/bill requests; D1-backed request tickets, per-table rate limiting, acknowledgement/resolution, manager floor map. Protect against requests sent from off-premises QR links. Do not promise waiter arrival time.
2. **Menu:** manager-controlled allergens, ingredients, spice, portion sizes and deals. Missing allergy data must say 'Ask staff'; never imply allergen-free without verified kitchen data.
3. **Kitchen:** station routing, per-order/item prep timestamps, manual status transitions and sound alerts; preserve existing orders.
4. **Payments:** split bill and tips as demo calculations first. Actual UPI/card checkout only after payment provider, webhook verification, refunds and reconciliation are configured. Cash is recorded by staff, not remotely confirmed by customers.
5. **Engagement:** verified Wi-Fi details, optional rewards and simple games; avoid collecting unnecessary personal data.
6. **Receipts:** email delivery only after opt-in and verified sending provider, no invented sender address.

## Release gates
- Keep separate staff security repository under development. Do not weaken existing API role checks.
- Make D1 schema changes additive and test against a separate test database first; back up production before any approved migration.
- Validate 20 QR tables, two phones at one table, order creation, kitchen updates, payment/receipt integrity, and unauthorized API calls.
- No production deployment without an explicit release decision after testing.
