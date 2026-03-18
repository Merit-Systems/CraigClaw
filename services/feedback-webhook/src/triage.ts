/**
 * Triage script — Craig runs this periodically to process pending feedback.
 * Classifies feedback and creates GitHub issues for bugs/features.
 *
 * Usage: FEEDBACK_WEBHOOK_SECRET=xxx tsx src/triage.ts
 */

import db from "./db.js";
import { execSync } from "child_process";

interface FeedbackRow {
  id: string;
  type: string;
  title: string;
  description: string;
  severity: string | null;
  product: string | null;
  session_context: string | null;
  steps: string | null;
  expected_behavior: string | null;
  actual_behavior: string | null;
  metadata: string | null;
  submitter: string | null;
  status: string;
  created_at: string;
}

const PRODUCT_TO_REPO: Record<string, string> = {
  agentcash: "Merit-Systems/agentcash",
  poncho: "Merit-Systems/poncho",
  x402scan: "Merit-Systems/x402scan",
  "the-stables": "Merit-Systems/the-stables",
  stablestudio: "Merit-Systems/the-stables",
  stableenrich: "Merit-Systems/the-stables",
  stablemail: "Merit-Systems/the-stables",
  stablephone: "Merit-Systems/the-stables",
  stablesocial: "Merit-Systems/the-stables",
  stableupload: "Merit-Systems/the-stables",
  openclaw: "Merit-Systems/openclaw",
  craig: "Merit-Systems/CraigClaw",
};

const DEFAULT_REPO = "Merit-Systems/agentcash";

function refreshGhToken(): void {
  try {
    const token = execSync("/home/ubuntu/.config/craig/get-github-token.sh 2>/dev/null", { encoding: "utf-8" }).trim();
    process.env.GH_TOKEN = token;
  } catch {
    console.warn("Could not refresh GH token, using existing");
  }
}

function severityToLabel(severity: string | null): string {
  switch (severity) {
    case "critical": return "priority: critical";
    case "high": return "priority: high";
    case "medium": return "priority: medium";
    case "low": return "priority: low";
    default: return "priority: medium";
  }
}

function typeToLabel(type: string): string {
  switch (type) {
    case "bug": return "bug";
    case "feature": return "feature";
    default: return "feedback";
  }
}

function buildIssueBody(row: FeedbackRow): string {
  const parts: string[] = [];

  parts.push(`## Description\n\n${row.description}`);

  if (row.steps) {
    try {
      const steps = JSON.parse(row.steps) as string[];
      parts.push(`## Steps to Reproduce\n\n${steps.map((s, i) => `${i + 1}. ${s}`).join("\n")}`);
    } catch {
      parts.push(`## Steps to Reproduce\n\n${row.steps}`);
    }
  }

  if (row.expected_behavior) parts.push(`## Expected Behavior\n\n${row.expected_behavior}`);
  if (row.actual_behavior) parts.push(`## Actual Behavior\n\n${row.actual_behavior}`);
  if (row.session_context) parts.push(`## Session Context\n\n\`\`\`\n${row.session_context}\n\`\`\``);
  if (row.submitter) parts.push(`## Submitted By\n\n${row.submitter}`);

  parts.push(`\n---\n*Auto-created from feedback webhook (ID: \`${row.id}\`)*`);

  return parts.join("\n\n");
}

function createGithubIssue(row: FeedbackRow): string | null {
  const repo = row.product ? (PRODUCT_TO_REPO[row.product.toLowerCase()] || DEFAULT_REPO) : DEFAULT_REPO;
  const labels = [typeToLabel(row.type), severityToLabel(row.severity), "agent-feedback"].join(",");
  const body = buildIssueBody(row);

  try {
    const result = execSync(
      `gh issue create --repo "${repo}" --title "${row.title.replace(/"/g, '\\"')}" --label "${labels}" --body "${body.replace(/"/g, '\\"').replace(/\n/g, "\\n")}"`,
      { encoding: "utf-8", timeout: 30_000 },
    );
    const url = result.trim();
    console.log(`  Created issue: ${url}`);
    return url;
  } catch (e) {
    console.error(`  Failed to create issue: ${e}`);
    return null;
  }
}

function isDismissable(row: FeedbackRow): boolean {
  if (row.title.length < 5 && row.description.length < 20) return true;
  const spamPatterns = [/test/i, /asdf/i, /hello/i, /^\.+$/];
  return spamPatterns.some((p) => p.test(row.title) && p.test(row.description));
}

function triage(): void {
  refreshGhToken();

  const pending = db.prepare("SELECT * FROM feedback WHERE status = 'pending' ORDER BY created_at ASC LIMIT 20").all() as FeedbackRow[];

  if (pending.length === 0) {
    console.log("No pending feedback to triage.");
    return;
  }

  console.log(`Triaging ${pending.length} pending feedback items...`);

  const updateStatus = db.prepare("UPDATE feedback SET status = ?, github_issue_url = ?, triaged_at = datetime('now') WHERE id = ?");

  for (const row of pending) {
    console.log(`\n[${row.type}] "${row.title}" (${row.severity || "no severity"})`);

    if (isDismissable(row)) {
      console.log("  Dismissed as noise");
      updateStatus.run("dismissed", null, row.id);
      continue;
    }

    if (row.type === "bug" || row.type === "feature") {
      const issueUrl = createGithubIssue(row);
      if (issueUrl) {
        updateStatus.run("issue_created", issueUrl, row.id);
      } else {
        updateStatus.run("triaged", null, row.id);
      }
    } else {
      updateStatus.run("triaged", null, row.id);
    }
  }

  console.log("\nTriage complete.");
}

triage();
