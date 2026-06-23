# Contributing to Canopus

Thanks for considering a contribution. Canopus is a small, focused package — keep changes scoped to its stated v1 goals (see `README.md` Roadmap for what's intentionally out of scope).

## Code of conduct

Be respectful and constructive in issues and pull requests. Disagreements about implementation are fine; personal attacks are not.

## Filing issues

Before opening an issue, search existing ones. When filing a bug report, include:

- Canopus version (`wally.toml` version or Creator Hub model version)
- Minimal repro (a single `lockName` + config + call sequence is usually enough)
- Expected vs. actual behavior
- Whether this happened in Studio or in a live server

## Pull request process

1. Open an issue first for anything beyond a trivial fix, so the approach can be agreed on before code is written.
2. Keep PRs focused — one logical change per PR.
3. Update or add tests for any behavioral change (see Testing below).
4. Make sure `selene src` and `stylua --check src tests examples` both pass.
5. Describe *why* the change is needed in the PR description, not just *what* changed.

## Coding style

- `--!strict` at the top of every file.
- Selene (`selene.toml`, `std = "roblox"`) and StyLua (`stylua.toml`) are enforced in CI — run both locally before pushing.
- No `_G`, `shared`, `loadstring`, `wait()`, `spawn()`, or `delay()`.
- No external runtime dependencies beyond `TestEZ` (dev-only). `HttpService:JSONEncode/Decode` is fine — it's a Roblox built-in, not an external package.
- Every public function is type-annotated, including its return type.
- Avoid magic numbers — add them to `src/Shared/Constants.lua`.

## Testing requirements

- New behavior needs a unit test under `tests/unit/` if it can be tested without `MemoryStoreService` (pure logic: `Config`, `LockEntry`, `Retry`, `Handle`).
- New behavior that depends on real `MemoryStoreService` semantics needs an integration test under `tests/integration/`, run manually in Studio with API Services enabled.
- Run the suite via `tests/runner.server.lua` (place it under `ServerScriptService`, already wired by `default.project.json`) before submitting.

## License agreement

By submitting a contribution, you agree it is licensed under the same terms as the rest of the project (see `LICENSE`).
