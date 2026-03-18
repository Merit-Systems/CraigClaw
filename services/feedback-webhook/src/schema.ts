export interface FeedbackSubmission {
  type: "bug" | "feature" | "feedback";
  title: string;
  description: string;
  severity?: "low" | "medium" | "high" | "critical";
  product?: string;
  sessionContext?: string;
  steps?: string[];
  expectedBehavior?: string;
  actualBehavior?: string;
  metadata?: Record<string, unknown>;
  submitter?: string;
}

export interface FeedbackRecord extends FeedbackSubmission {
  id: string;
  status: "pending" | "triaged" | "issue_created" | "pr_created" | "rewarded" | "dismissed";
  githubIssueUrl?: string;
  rewardAmountUsdc?: number;
  createdAt: string;
  triagedAt?: string;
  resolvedAt?: string;
}

export function validateSubmission(body: unknown): { valid: true; data: FeedbackSubmission } | { valid: false; error: string } {
  if (!body || typeof body !== "object") return { valid: false, error: "Body must be a JSON object" };

  const b = body as Record<string, unknown>;

  if (!["bug", "feature", "feedback"].includes(b.type as string)) {
    return { valid: false, error: "type must be 'bug', 'feature', or 'feedback'" };
  }
  if (typeof b.title !== "string" || b.title.length < 3) {
    return { valid: false, error: "title must be a string with at least 3 characters" };
  }
  if (typeof b.description !== "string" || b.description.length < 10) {
    return { valid: false, error: "description must be a string with at least 10 characters" };
  }
  if (b.severity !== undefined && !["low", "medium", "high", "critical"].includes(b.severity as string)) {
    return { valid: false, error: "severity must be 'low', 'medium', 'high', or 'critical'" };
  }
  if (b.steps !== undefined && !Array.isArray(b.steps)) {
    return { valid: false, error: "steps must be an array of strings" };
  }

  return {
    valid: true,
    data: {
      type: b.type as FeedbackSubmission["type"],
      title: b.title as string,
      description: b.description as string,
      severity: b.severity as FeedbackSubmission["severity"],
      product: b.product as string | undefined,
      sessionContext: b.sessionContext as string | undefined,
      steps: b.steps as string[] | undefined,
      expectedBehavior: b.expectedBehavior as string | undefined,
      actualBehavior: b.actualBehavior as string | undefined,
      metadata: b.metadata as Record<string, unknown> | undefined,
      submitter: b.submitter as string | undefined,
    },
  };
}
