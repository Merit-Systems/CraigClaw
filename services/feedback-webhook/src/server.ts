import { Hono } from "hono";
import { serve } from "@hono/node-server";
import { randomUUID } from "crypto";
import db from "./db.js";
import { validateSubmission } from "./schema.js";

const app = new Hono();

const WEBHOOK_SECRET = process.env.FEEDBACK_WEBHOOK_SECRET || "changeme";
const PORT = parseInt(process.env.FEEDBACK_PORT || "3847", 10);

// auth middleware
app.use("/api/*", async (c, next) => {
  const auth = c.req.header("Authorization");
  if (auth !== `Bearer ${WEBHOOK_SECRET}`) {
    return c.json({ error: "Unauthorized" }, 401);
  }
  await next();
});

// health check (no auth)
app.get("/health", (c) => c.json({ status: "ok", pending: getPendingCount() }));

// submit feedback
app.post("/api/feedback", async (c) => {
  const body = await c.req.json().catch(() => null);
  const result = validateSubmission(body);

  if (!result.valid) {
    return c.json({ error: result.error }, 400);
  }

  const { data } = result;
  const id = randomUUID();

  const insert = db.prepare(`
    INSERT INTO feedback (id, type, title, description, severity, product, session_context, steps, expected_behavior, actual_behavior, metadata, submitter)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  insert.run(
    id,
    data.type,
    data.title,
    data.description,
    data.severity || null,
    data.product || null,
    data.sessionContext || null,
    data.steps ? JSON.stringify(data.steps) : null,
    data.expectedBehavior || null,
    data.actualBehavior || null,
    data.metadata ? JSON.stringify(data.metadata) : null,
    data.submitter || null,
  );

  return c.json({ id, status: "received", message: "Feedback submitted. We'll triage it shortly." }, 201);
});

// list feedback (for Craig's triage review)
app.get("/api/feedback", (c) => {
  const status = c.req.query("status") || "pending";
  const limit = Math.min(parseInt(c.req.query("limit") || "50", 10), 200);

  const rows = db.prepare("SELECT * FROM feedback WHERE status = ? ORDER BY created_at DESC LIMIT ?").all(status, limit);
  return c.json({ count: rows.length, feedback: rows });
});

// get single feedback
app.get("/api/feedback/:id", (c) => {
  const row = db.prepare("SELECT * FROM feedback WHERE id = ?").get(c.req.param("id"));
  if (!row) return c.json({ error: "Not found" }, 404);
  return c.json(row);
});

// update feedback status (used by triage script)
app.patch("/api/feedback/:id", async (c) => {
  const id = c.req.param("id");
  const body = await c.req.json().catch(() => ({})) as Record<string, unknown>;

  const updates: string[] = [];
  const values: unknown[] = [];

  if (body.status) { updates.push("status = ?"); values.push(body.status); }
  if (body.githubIssueUrl) { updates.push("github_issue_url = ?"); values.push(body.githubIssueUrl); }
  if (body.rewardAmountUsdc) { updates.push("reward_amount_usdc = ?"); values.push(body.rewardAmountUsdc); }
  if (body.status === "triaged") { updates.push("triaged_at = datetime('now')"); }
  if (body.status === "rewarded" || body.status === "dismissed") { updates.push("resolved_at = datetime('now')"); }

  if (updates.length === 0) return c.json({ error: "No valid fields to update" }, 400);

  values.push(id);
  db.prepare(`UPDATE feedback SET ${updates.join(", ")} WHERE id = ?`).run(...values);

  const row = db.prepare("SELECT * FROM feedback WHERE id = ?").get(id);
  return c.json(row);
});

// bulk submit (JSONL-style array)
app.post("/api/feedback/bulk", async (c) => {
  const body = await c.req.json().catch(() => null);
  if (!Array.isArray(body)) return c.json({ error: "Body must be an array" }, 400);
  if (body.length > 100) return c.json({ error: "Max 100 items per batch" }, 400);

  const results: Array<{ id?: string; error?: string; index: number }> = [];
  const insert = db.prepare(`
    INSERT INTO feedback (id, type, title, description, severity, product, session_context, steps, expected_behavior, actual_behavior, metadata, submitter)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  const batchInsert = db.transaction((items: typeof body) => {
    for (let i = 0; i < items.length; i++) {
      const result = validateSubmission(items[i]);
      if (!result.valid) {
        results.push({ index: i, error: result.error });
        continue;
      }
      const { data } = result;
      const id = randomUUID();
      insert.run(id, data.type, data.title, data.description, data.severity || null, data.product || null, data.sessionContext || null, data.steps ? JSON.stringify(data.steps) : null, data.expectedBehavior || null, data.actualBehavior || null, data.metadata ? JSON.stringify(data.metadata) : null, data.submitter || null);
      results.push({ index: i, id });
    }
  });

  batchInsert(body);
  return c.json({ submitted: results.filter((r) => r.id).length, errors: results.filter((r) => r.error).length, results }, 201);
});

function getPendingCount(): number {
  const row = db.prepare("SELECT COUNT(*) as count FROM feedback WHERE status = 'pending'").get() as { count: number };
  return row.count;
}

console.log(`Feedback webhook listening on port ${PORT}`);
serve({ fetch: app.fetch, port: PORT });

export default app;
