# Python Agents: uv + Virtual Environments

This guide explains how Python-based agents should use `uv` for dependency and environment management in this monorepo. It focuses on conventions and developer workflow guidance rather than prescribing a specific implementation.

## Goals

- Use `uv` to manage Python dependencies and create project-local virtual environments.
- Keep environments ephemeral and out of version control.
- Keep source-of-truth in `pyproject.toml` (and `uv.lock` when appropriate).

## Project Layout

- Python projects live under `apps/`, `packages/`, or `tools/` as needed.
- Each Python project should have its own `pyproject.toml` at the project root.
- Do not share virtual environments across projects; keep them project-local.

## Virtual Environments

- Preferred location: a project-local `.venv/` directory (ignored by git).
- Recommended creation flows:
  - `uv venv` to create a `.venv/` explicitly, or
  - `uv sync` to create/populate the environment from `pyproject.toml` (and `uv.lock` if present).
- Activation is optional; prefer `uv run` to execute commands inside the env without manual activation.

Examples (guidance only):

```
# From a Python project root
uv venv                 # or: uv sync
uv run python -m app    # run code within the environment
uv run pytest           # run tests within the environment
```

## Dependencies and Lockfiles

- Declare dependencies in `pyproject.toml`.
- Generate a lockfile with `uv lock` when you need reproducibility.
- Commit policy:
  - Applications: commit `uv.lock` to ensure reproducible builds.
  - Libraries: optional; follow the team’s publishing workflow.

## Version Management

- Use `uv` to resolve/install appropriate Python versions when needed.
- The repo does not enforce a single global Python version. Projects may pin a version via `pyproject.toml` constraints or a `.python-version` file if desired.

## Git Hygiene

- `.venv/` is ignored globally by `.gitignore`.
- Keep the environment ephemeral; never commit compiled artifacts or venv contents.

## Bazel Interop (Optional)

- Bazel builds may use `rules_python`. When doing so, prefer Bazel-managed hermetic deps for build/test steps.
- Local development can still rely on `uv` and `.venv/` for a fast feedback loop.

## CI Recommendations

- In CI, create ephemeral environments via `uv sync` and run steps with `uv run`.
- Cache only what your CI system supports reliably (e.g., `uv` download cache). Do not cache `.venv/` in the repo.

## Summary

- One project → one `pyproject.toml` → one local `.venv/` (ignored).
- Use `uv sync` and `uv run` for a smooth developer workflow.
- Commit `uv.lock` for applications; optional for libraries.