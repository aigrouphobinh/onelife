# OneLife – 15-minute GitHub Actions autopilot

**Implemented as a deterministic, free GitHub Actions workflow**, not a ChatGPT scheduled task, cloud LLM, or a full autonomous code-generating agent.

- Workflow: `.github/workflows/onelife-autopilot-15m.yml`
- Worker: `tools/onelife_autopilot.py`
- Schedule: UTC minute **07, 22, 37, 52** every hour (`7,22,37,52 * * * *`); the same minute marks apply in Vietnam.
- Manual run: GitHub → Actions → **OneLife - 15 minute auto progress** → **Run workflow**.
- Review results: job summary, `docs/NEXT_AUTO_TASK.md`, `docs/OTHER_MASCOT_COVERAGE.md` and `design/review/reports/other-mascot-coverage.json`.
- Disable: Actions → workflow → **Disable workflow**, or remove `on.schedule` in the YAML.

## Actual supported work on each run

1. Inspect the registered illustration sources in `assets/characters-v2/animation_sources.json`. Verify that each source file exists, that its declared SHA-256 matches, and that its character/state is allowed and unique.
2. Select at most **one source-backed pending animation** whose PNG/GIF/metadata are absent, outdated or inconsistent. Render its real illustrated frames using the existing `render_glossy_character_animation.py` importer. Never invent a drawing, frame, task completion, or hash.
3. Reconcile the Cat animation gallery with the verified state manifest, updating the state menu and frame timing without placeholder entries.
4. Run the existing character coverage and gallery QA and update the Cat contact sheet when a new state was imported.
5. Write `docs/NEXT_AUTO_TASK.md` pointing to the first missing character/state and precise input needed for an artist/AI task.
6. Commit and push validated changes to `main` using GitHub's built-in token, **only if there is a real diff**. Other user's commits are kept through `git fetch` + `git rebase`; failures stop safely.

## Limits, safety, and no-cost policy

- **Creative tasks requiring new art, code logic, model inference or user testing are NOT automatically completed.** Without a connected coding/image agent and its operating environment, this workflow cannot invent new independently illustrated sprites, implement Flutter, or approve art on a phone. The next missing task is documented as *blocked* instead.
- No commercial or trial API keys are used; all checks run locally within GitHub-hosted jobs. GitHub Actions quota/usage applies according to repository/account settings.
- Work is limited to approved source-backed mascot asset imports, QA and documentation. It does not change the OS permissions, gather phone data, delete existing art, or claim product readiness.
- No timestamp-only commits, repeated empty commits, or false progress. The workflow writes a job summary every run while leaving git unchanged when nothing is actionable.
- GitHub scheduled jobs are **best effort**, not a guaranteed precise clock; they can start late or be skipped under load. On some public repositories inactivity can disable scheduled workflows after 60 days.
- `contents: write` permission is requested on the workflow. Repository Actions settings/branch protections may still prevent auto-push; a failed push is reported, not silently treated as success.
- A single recurring workflow is used to avoid concurrent duplicate workers; `timeout-minutes: 12` bounds execution.

## First expected task

At time of setup, the repository has **Cat 10/15** original illustrated sources. The next missing original-art source is **Cat Done** (`cat/done`), followed by Thinking, Sad, Balanced and Strained. The worker can complete import/QA **when a true source atlas is added**; creating the original new art still requires an art-generation agent or human designer.