# Agent Context

**This repo:** `ffreis-workflows-python` — reusable GitHub Actions workflow library for
Python projects. Covers ruff fmt/lint, mypy, pytest, coverage, pip-audit, container
build, uv lock sync, Hypothesis property tests, Semgrep SAST, docs, and benchmarks.

## Non-obvious rules (read before changing anything)

1. **`devops-*.yml` workflows are exempt from `self-test.yml`.** All `python-*.yml`
   workflows must appear in `self-test.yml`.

2. **`uv.lock` must always exist.** Workflows run `uv sync --frozen`. If the lock file
   is missing, the workflow fails immediately. Do not add fallback logic.

3. **Space-separated extras expand via bash array:**
   ```bash
   read -r -a extras_arr <<< "$UV_EXTRAS"
   ```
   Do not change this pattern — callers rely on the exact expansion behavior.

4. **Codecov requires fork PR gate** (token unavailable on forks):
   ```yaml
   if: github.event_name != 'pull_request' || github.event.pull_request.head.repo.fork == false
   ```

5. **Shell injection prevention enforced by Semgrep.** Route all inputs through `env:`.

6. **`setup-uv` SHA and all third-party action SHAs managed by Renovate.**

## Structure

```
.github/workflows/
  python-*.yml    ← reusable library
  devops-*.yml    ← repo-maintenance (exempt from self-test)
  ci.yml
examples/hello/   ← Python project with ruff config
```

## Build/test

```bash
make setup              # lefthook + gitleaks + ruff check
make lint               # actionlint + ruff examples/hello
make fmt-check          # ruff format --check
make secrets-scan-staged
```
