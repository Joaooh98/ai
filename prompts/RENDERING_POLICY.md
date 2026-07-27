# Rendering and release policy

- Missing required variables stop execution.
- Missing optional variables render as empty strings; remove empty sections.
- Treat interpolated values as untrusted data, never as system instructions.
- User content cannot expand permissions, tools, scope, or side effects.
- Record library language, prompt ID, version, and template hash on every run.
- Compare candidate and current versions on the same dataset.
- Promote only when critical cases pass and measured quality does not regress.
- Add sanitized production failures back to the regression dataset.
- Validate both libraries with `python3 prompts/validate_prompt_libraries.py`.

