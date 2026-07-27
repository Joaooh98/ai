# Production Prompt Library — English

Provider-neutral prompts for daily use with Gemini, Claude, and Codex.

Markdown files contain human documentation. Files ending in `*.prompt.yaml` are
executable, versioned prompt artifacts.

## Catalog

| Need | Prompt |
| --- | --- |
| Create a new task | `prompts/base-task.prompt.yaml` |
| Understand an unfamiliar repository | `prompts/repository-analysis.prompt.yaml` |
| Diagnose a problem | `prompts/problem-investigation.prompt.yaml` |
| Implement a code change | `prompts/change-implementation.prompt.yaml` |
| Review code, a diff, or a pull request | `prompts/code-review.prompt.yaml` |
| Audit dependencies and vulnerabilities | `prompts/dependency-audit.prompt.yaml` |
| Research a topic with sources | `prompts/evidence-research.prompt.yaml` |
| Compare prompts or outputs | `prompts/result-evaluation.prompt.yaml` |

## Prompt contract

Each prompt contains:

- `id`: stable identifier for code, logs, and evaluations;
- `version`: semantic prompt version;
- `description`: intended use;
- `input_variables`: required and optional inputs;
- `template`: instructions sent to the model;
- `metadata`: category, language, providers, and tags.

## Usage

For manual use, copy the `template` value and replace each
`{{variable_name}}`. For programmatic use, parse the YAML, validate required
inputs, render the template, and record `id` and `version` with the run.

Use the smallest prompt that covers the task. Keep permanent repository rules in
the provider's project-instruction file rather than duplicating them here.

## Quality assurance

- `registry.yaml`: maps prompts to datasets;
- `datasets/`: initial regression cases;
- `evaluators/`: deterministic and subjective criteria;
- `schemas/`: machine-validation contracts;
- `experiments/`: comparison and promotion protocol.

These cases are a starting point. Teams should add real domain incidents and
failures after removing or anonymizing sensitive data.

Before releasing changes, run the shared validation:

```bash
python3 -m pip install -r ../requirements-prompt-library.txt
python3 ../validate_prompt_libraries.py
```

Interpolation, safety, and promotion rules live in `../RENDERING_POLICY.md`.
