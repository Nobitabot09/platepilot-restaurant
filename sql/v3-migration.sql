-- PlatePilot V3 migration. Run once against the PlatePilot D1 database.
ALTER TABLE order_items ADD COLUMN spice TEXT DEFAULT 'medium';
ALTER TABLE order_items ADD COLUMN extras TEXT DEFAULT '[]';
ALTER TABLE order_items ADD COLUMN instructions TEXT DEFAULT '';
CREATE TABLE IF NOT EXISTS feedback (order_id INTEGER PRIMARY KEY, rating INTEGER NOT NULL CHECK(rating BETWEEN 1 AND 5), comment TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL DEFAULT (datetime('now')));
CREATE TABLE IF NOT EXISTS order_events (id INTEGER PRIMARY KEY AUTOINCREMENT,order_id INTEGER NOT NULL,status TEXT NOT NULL,created_at TEXT NOT NULL DEFAULT (datetime('now')));
CREATE TABLE IF NOT EXISTS login_attempts (ip_hash TEXT PRIMARY KEY,attempts INTEGER NOT NULL DEFAULT 0,blocked_until INTEGER NOT NULL DEFAULT 0);
CREATE TABLE IF NOT EXISTS order_rate (ip_hash TEXT PRIMARY KEY,window_start INTEGER NOT NULL,count INTEGER NOT NULL);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status,created_at);
