# feedback-webhook

Agent feedback collection → auto-triage → GitHub issues → USDC rewards.

Agents submit bug reports, feature requests, and general feedback via webhook. Craig triages them automatically into GitHub issues across Merit-Systems repos.

## Quick Start

```bash
npm install
FEEDBACK_WEBHOOK_SECRET=your-secret npm run dev
```

## Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/health` | No | Health check + pending count |
| POST | `/api/feedback` | Bearer | Submit single feedback |
| POST | `/api/feedback/bulk` | Bearer | Submit up to 100 items |
| GET | `/api/feedback` | Bearer | List feedback (query: `?status=pending&limit=50`) |
| GET | `/api/feedback/:id` | Bearer | Get single feedback |
| PATCH | `/api/feedback/:id` | Bearer | Update status/issue URL |

## Submit Feedback

```bash
curl -X POST http://localhost:3847/api/feedback \
  -H "Authorization: Bearer your-secret" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "bug",
    "title": "AgentCash fails on non-discovery endpoints",
    "description": "When hitting endpoints that are not agentcash-discovery-compatible, the request silently fails with no error message.",
    "severity": "high",
    "product": "agentcash",
    "steps": ["Configure a non-discovery endpoint", "Attempt to call via AgentCash", "Observe silent failure"],
    "expectedBehavior": "Should fall back to direct x402 payment",
    "actualBehavior": "Silent failure, no error"
  }'
```

## Feedback Schema

```typescript
{
  type: "bug" | "feature" | "feedback"  // required
  title: string                          // required, min 3 chars
  description: string                    // required, min 10 chars
  severity?: "low" | "medium" | "high" | "critical"
  product?: string                       // maps to Merit-Systems repo
  sessionContext?: string                // agent session logs (strip sensitive data first)
  steps?: string[]                       // repro steps
  expectedBehavior?: string
  actualBehavior?: string
  metadata?: Record<string, any>         // anything else
  submitter?: string                     // agent/user identifier
}
```

## Triage

Run manually or on a cron:

```bash
FEEDBACK_WEBHOOK_SECRET=your-secret npm run triage
```

This processes pending feedback, creates GitHub issues for bugs/features, and dismisses noise.

## Product → Repo Mapping

| Product | Repo |
|---------|------|
| agentcash | Merit-Systems/agentcash |
| poncho | Merit-Systems/poncho |
| x402scan | Merit-Systems/x402scan |
| the-stables, stablestudio, stableenrich, stablemail, stablephone, stablesocial, stableupload | Merit-Systems/the-stables |
| openclaw | Merit-Systems/openclaw |
| craig | Merit-Systems/CraigClaw |

## Roadmap

- [ ] USDC rewards for useful feedback via x402
- [ ] Auto-PR attempts for well-described bugs
- [ ] AgentCash skill integration (agents submit feedback natively)
- [ ] Rate limiting per submitter
- [ ] Webhook notifications to Discord on new submissions
