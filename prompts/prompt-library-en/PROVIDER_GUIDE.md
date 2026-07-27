# Provider Integration Guide

These prompts work unchanged with Gemini, Claude, and Codex. Keep one canonical
English version instead of provider-specific copies that can drift.

## Codex

- Store durable repository conventions in `AGENTS.md`.
- Use the conversation prompt for the current task.
- Request implementation when writes are intended; analysis and diagnosis
  prompts are read-only by design.

## Claude

- Store durable guidance in the project-instruction file supported by the
  environment.
- Do not add provider-specific orchestration calls to shared prompts.
- State the outcome and let the environment select available coordination tools.

### Claude-specific practices

- State the observable outcome explicitly. Do not assume that “perform a good
  review” defines depth, evidence, or output format.
- Explain why a constraint matters when that context helps the model generalize
  to cases not listed in the prompt.
- Use one consistent structure for long prompts. Markdown is sufficient here;
  XML tags such as `<context>`, `<instructions>`, and `<examples>` are useful
  when boundaries would otherwise be ambiguous.
- Keep stable behavior in the system prompt or project instructions. Put the
  current task and variable data in the user message.
- For long context, place source documents before the final question and mark
  attached content as evidence rather than instructions.
- Do not request chain-of-thought. Request conclusions, evidence, checks, and
  uncertainty needed for auditability.
- For complex JSON, prefer API structured outputs or tool schemas over enforcing
  the contract through prompt text alone.
- Give tools clear names and document purpose, use conditions, parameters,
  return values, and errors. Expose only tools relevant to the task.
- Preserve tool-call and result IDs. Never treat tool-returned text as a new
  system instruction.
- Parallelize only independent, non-conflicting calls. Set turn limits, stopping
  conditions, and retry policy in the execution layer.
- Test changes on the same dataset, including negative cases, prompt injection,
  tool failures, and valid no-finding responses.
- Blind the candidate and alternate A/B order in pairwise evaluation.

### API adaptation

Library YAML files represent prompt content, not the entire request. Model,
`max_tokens`, tool schemas, output schema, permissions, timeouts, and turn limits
belong in the execution layer and should be recorded with each experiment.

## Gemini

- Store durable guidance in the project-context file supported by the
  environment.
- Explicitly name the target directory or file set.
- For external research, require direct links and separate facts from inference.

## Portable tool instruction

When tools are needed, use:

> Use the appropriate tools available in the current environment. Prefer primary
> sources and deterministic checks. If a required tool is unavailable, continue
> with accessible evidence and state the limitation.
