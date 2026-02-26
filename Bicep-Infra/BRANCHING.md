# Branching recommendation

As requested, use `Develop` as the integration branch for infrastructure changes.

- `main` → production-ready, tagged releases.
- `Develop` → default branch for active infra development.
- `feature/*` → short-lived feature branches merged into `Develop`.
- `release/*` (optional) → hardening before merge to `main`.

Typical flow:
1. Create `feature/logicapp-<name>` from `Develop`.
2. Add/update entries in `environments/<env>/main.parameters.json`.
3. Open PR to `Develop`.
4. Promote from `Develop` to `main` when validated.
