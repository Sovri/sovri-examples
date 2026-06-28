# sovri-examples

Example configs and the cross-repository acceptance suite for the Sovri
project-level compliance platform. Scaffolded by MAT-81.

## Acceptance suite

`tests/acceptance.sh` is an offline end-to-end suite that verifies the MAT-81
repository-setup rules across the three scaffolded repositories
(`sovri-agent`, `sovri-sdk-rust`, `sovri-frameworks`) as on-disk siblings. It
mirrors the Gherkin features under `specs/`.

```sh
# Place the three repositories under ./repos (or pass a directory):
mkdir -p repos
for r in sovri-agent sovri-sdk-rust sovri-frameworks; do
  git clone https://github.com/Sovri/$r.git repos/$r
done

./tests/acceptance.sh ./repos
```

The assertions themselves run with no network access. Cloning the sibling repos
needs network; once they are on disk, the suite is fully offline. CI
(`.github/workflows/e2e.yml`) clones the three repositories and runs the suite on
every pull request.

### What it checks

- R-01 — each repository documents its build/test/lint commands.
- R-02 — CI declares the format/lint/test/build (or catalog structure) gates and
  every action is pinned by commit SHA.
- R-03 — `sovri-frameworks` ships the six placeholder family directories.
- R-04 — `sovri-agent selftest` runs offline, exits 0, and reports a version.
- R-05 — each repository documents the Community/Open Core boundary and air-gap.
- R-06 — crates build offline, the secret guard blocks a `.env`, and CI needs no
  repository secrets.

This suite goes fully green once the three foundation repositories are merged;
until then it reflects whichever state of those repositories is on disk.

## License

Apache-2.0. See `LICENSE` and `NOTICE`.
