import Database from "better-sqlite3";
import { existsSync, mkdirSync } from "fs";
import { join, dirname } from "path";

const DB_PATH = process.env.FEEDBACK_DB_PATH || join(dirname(new URL(import.meta.url).pathname), "..", "data", "feedback.db");

// ensure data dir exists
const dataDir = dirname(DB_PATH);
if (!existsSync(dataDir)) mkdirSync(dataDir, { recursive: true });

const db = new Database(DB_PATH);
db.pragma("journal_mode = WAL");

db.exec(`
  CREATE TABLE IF NOT EXISTS feedback (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL CHECK(type IN ('bug', 'feature', 'feedback')),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    severity TEXT CHECK(severity IN ('low', 'medium', 'high', 'critical')),
    product TEXT,
    session_context TEXT,
    steps TEXT,
    expected_behavior TEXT,
    actual_behavior TEXT,
    metadata TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending', 'triaged', 'issue_created', 'pr_created', 'rewarded', 'dismissed')),
    github_issue_url TEXT,
    reward_amount_usdc REAL,
    submitter TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    triaged_at TEXT,
    resolved_at TEXT
  );

  CREATE INDEX IF NOT EXISTS idx_feedback_status ON feedback(status);
  CREATE INDEX IF NOT EXISTS idx_feedback_type ON feedback(type);
  CREATE INDEX IF NOT EXISTS idx_feedback_created ON feedback(created_at);
`);

export default db;
