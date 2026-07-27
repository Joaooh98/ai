# Experiment Protocol

Each run must record prompt and dataset versions, provider, model, parameters,
tools, date, outputs, scores, tokens, cost, and latency when available.

1. Run the current and candidate versions on the same dataset.
2. Run deterministic checks before subjective judging.
3. Blind candidate identity and alternate A/B order.
4. Compare quality, false positives, cost, latency, and stability.
5. Require human review for security or high-impact decisions.
6. Promote only when thresholds pass and critical cases do not regress.
7. Turn real failures into new cases without sensitive data.

Store results separately from prompts. Ignore sensitive runs in Git; version
aggregated results when an audit trail is required.

