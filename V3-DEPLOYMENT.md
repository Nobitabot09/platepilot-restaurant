# PlatePilot V3

Independent Cloudflare Pages Direct Upload project. This repository does not touch Flayora projects.

## Deployment

Cloudflare Pages project: `platepilot-restaurant`. Production: https://platepilot-restaurant.pages.dev

Deploy the root `_worker.js` as a Pages advanced-mode Worker with an empty assets manifest, using Cloudflare Pages Direct Upload. **Pushing to GitHub alone does not deploy this project**, since it is not Git-integrated.

D1 binding `DB` points to `platepilot-db`. Required production secrets: `ADMIN_PASSWORD` (manager), `KITCHEN_PASSWORD` (kitchen), `SESSION_SECRET`. Set `TABLE_COUNT=20`. Do not commit secret values. The manager password was shared earlier in the conversation and should be rotated before production.

Database has been migrated using `sql/v3-migration.sql`; do not rerun the three `ALTER TABLE` statements on an already migrated DB.

## Features

- Customer menu, dish modal with spice/extras/instructions, cart and order submission
- Status tracker, reorder from last order stored locally, feedback after served
- Kitchen order polling (3 seconds), browser speech/desktop notifications, elapsed time and overdue warnings, print kitchen tickets
- Kitchen and manager login roles; manager-only menu editing, analytics and history
- D1 storage, login lockout after repeated failures, basic order-rate limit, server-side price calculations

## Known limitations / acceptance checks

- Cloudflare deployment status and JavaScript parse checks have been verified; **full real-browser end-to-end testing remains outstanding**.
- Browser voice and notifications require user permission; alerts only work while the kitchen screen remains open. This is polling, not WebSocket/push delivery.
- Customer reorder is stored in the browser and does not automatically resubmit.
- External food image and QR providers may fail or be blocked; use first-party assets for production.
- No payment gateway, taxes, refunds, inventory decrement, automated receipt printer or multi-restaurant tenancy.
- Basic abuse protection is not a substitute for Cloudflare WAF, Turnstile, audit logging and production load testing.
- Revenue reports count **served** orders, not confirmed payments; treat these as operational sales estimates.

## Manual acceptance test

1. Load menu and open dish image; set spice, extras and note. Confirm price increases correctly.
2. Place an order on table 1. Record order number and tracking token.
3. Sign in as kitchen, confirm order appears and change new → preparing → ready → served.
4. Verify customer tracking updates; submit one feedback entry; reject duplicate.
5. Sign in as manager, change availability and confirm customer menu updates.
6. Confirm kitchen role cannot edit menu or view analytics.
7. Print a kitchen ticket; verify manager history, daily sales and top dishes.
8. Verify incorrect passwords are rejected, lockout applies, and order rate limit responds after excessive submissions.
9. Test mobile screen, slow network, images, keyboard navigation and browser audio permissions.
