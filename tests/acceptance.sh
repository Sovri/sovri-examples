#!/usr/bin/env bash
# Offline acceptance suite for MAT-81 (repository setup).
# Verifies rules R-01..R-06 across the three scaffolded repositories as on-disk
# siblings. No network access is required to run the assertions.
#
# Usage: tests/acceptance.sh [REPOS_DIR]
#   REPOS_DIR defaults to ./repos and must contain sovri-agent, sovri-sdk-rust,
#   and sovri-frameworks checkouts.
set -uo pipefail

ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)/repos}"
AGENT="$ROOT/sovri-agent"
SDK="$ROOT/sovri-sdk-rust"
FW="$ROOT/sovri-frameworks"

pass=0
fail=0
ok()  { printf '  PASS  %s\n' "$1"; pass=$((pass + 1)); }
ko()  { printf '  FAIL  %s\n' "$1"; fail=$((fail + 1)); }
skip(){ printf '  SKIP  %s\n' "$1"; }

for d in "$AGENT" "$SDK" "$FW"; do
  if [ ! -d "$d" ]; then
    echo "FATAL: missing repo checkout: $d" >&2
    exit 2
  fi
done

tmpd="$(mktemp -d)"
cleanup() { rm -rf "$tmpd"; }
trap cleanup EXIT

echo "== R-01: documented build/test/lint commands per repository =="
for r in "$AGENT" "$SDK"; do
  if bash "$r/scripts/check-docs.sh" "$r/README.md" >/dev/null 2>&1; then
    ok "$(basename "$r") README documents build/test/lint"
  else
    ko "$(basename "$r") README documented commands"
  fi
done
if bash "$FW/scripts/check-docs.sh" "$FW/README.md" >/dev/null 2>&1; then
  ok "sovri-frameworks README documents catalog lint + validate commands"
else
  ko "sovri-frameworks documented commands"
fi
# violation: a README missing the lint command is detected and the lint named
nolint="$tmpd/README.nolint.md"
grep -v 'cargo fmt --check && cargo clippy' "$SDK/README.md" > "$nolint"
out="$(bash "$SDK/scripts/check-docs.sh" "$nolint" 2>&1)"; rc=$?
if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q 'lint command'; then
  ok "missing lint command is detected and named"
else
  ko "missing lint command detection"
fi

echo "== R-02: CI fails on format/lint/test/build errors =="
for r in "$AGENT" "$SDK"; do
  ci="$r/.github/workflows/ci.yml"
  if grep -q 'cargo fmt' "$ci" && grep -q 'clippy' "$ci" && grep -q 'cargo build' "$ci" && grep -q 'cargo test' "$ci"; then
    ok "$(basename "$r") CI declares fmt + clippy + build + test gates"
  else
    ko "$(basename "$r") CI gates"
  fi
done
if grep -q 'check-structure.sh' "$FW/.github/workflows/ci.yml"; then
  ok "sovri-frameworks CI declares the catalog structure gate"
else
  ko "sovri-frameworks catalog structure gate"
fi
# @technical: every third-party action is pinned by 40-hex commit SHA
for r in "$AGENT" "$SDK" "$FW"; do
  if ( cd "$r" && bash scripts/check-action-pins.sh >/dev/null 2>&1 ); then
    ok "$(basename "$r") actions are SHA-pinned"
  else
    ko "$(basename "$r") action SHA pinning"
  fi
done
# violation: frameworks catalog gate fails when a family directory is missing
fixt="$tmpd/fw/frameworks"
mkdir -p "$fixt/gdpr-eprivacy" "$fixt/iso27001" "$fixt/dora" "$fixt/ai-act" "$fixt/custom"
out="$(bash "$FW/scripts/check-structure.sh" "$fixt" 2>&1)"; rc=$?
if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q 'nis2'; then
  ok "catalog structure gate fails and names the missing family (nis2)"
else
  ko "catalog structure gate violation detection"
fi

echo "== R-03: framework catalog placeholder structure =="
miss=""
for fam in gdpr-eprivacy iso27001 nis2 dora ai-act custom; do
  [ -d "$FW/frameworks/$fam" ] || miss="$miss $fam"
done
[ -z "$miss" ] && ok "all six family directories present" || ko "missing families:$miss"
{ [ -d "$FW/frameworks" ] && [ ! -d "$FW/farameworks" ]; } && ok "catalogs under correctly spelled frameworks/" || ko "frameworks/ spelling"
frr="$FW/frameworks/README.md"
if grep -q 'framework.yaml' "$frr" && grep -Eq 'controls|rules|mappings' "$frr" && grep -Eqi 'later ticket|MAT-84' "$frr"; then
  ok "frameworks/README.md documents layout + defers content to a later ticket"
else
  ko "frameworks/README.md layout documentation"
fi
if ( cd "$FW" && git ls-files frameworks/ai-act 2>/dev/null | grep -q . ) \
   || [ -n "$(find "$FW/frameworks/ai-act" -type f 2>/dev/null)" ]; then
  ok "ai-act has a tracked placeholder file so the empty dir is versioned"
else
  ko "ai-act placeholder file"
fi

echo "== R-04: agent runs a placeholder command offline =="
if command -v cargo >/dev/null 2>&1; then
  if cargo build --quiet --manifest-path "$AGENT/Cargo.toml" >/dev/null 2>&1; then
    bin="$AGENT/target/debug/sovri-agent"
    out="$("$bin" selftest 2>/dev/null)"; rc=$?
    { [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -Eq '[0-9]+\.[0-9]+\.[0-9]+'; } \
      && ok "sovri-agent selftest exits 0 and prints a version status line" \
      || ko "sovri-agent selftest output"
    # no environment configuration required: run with an empty environment
    env -i "$bin" selftest >/dev/null 2>&1 && ok "selftest needs no environment configuration" || ko "selftest with empty env"
  else
    ko "sovri-agent build"
  fi
else
  skip "R-04 selftest (cargo not available)"
fi

echo "== R-05: docs explain Open Core boundaries and air-gap =="
for r in "$AGENT" "$SDK" "$FW"; do
  rd="$r/README.md"
  if grep -qiE '^##[[:space:]]+Community and Open Core' "$rd" && grep -qF 'Apache-2.0' "$rd" && grep -qiE '^##[[:space:]]+Air.?gap' "$rd"; then
    ok "$(basename "$r") README has boundary + Apache-2.0 + air-gap"
  else
    ko "$(basename "$r") boundary/air-gap sections"
  fi
done
if grep -qi 'catalog' "$FW/README.md" && grep -qiE 'no external API|not.*(LLM|language model)|versioned catalog' "$FW/README.md"; then
  ok "frameworks air-gap states framework text comes from versioned catalogs, not an LLM"
else
  ko "frameworks air-gap catalog-not-LLM statement"
fi
# violation: README missing the air-gap section is detected
noair="$tmpd/README.noair.md"
awk 'BEGIN{skip=0} /^##[[:space:]]+Air/{skip=1} /^##[[:space:]]+License/{skip=0} skip==0{print}' "$AGENT/README.md" > "$noair"
out="$(bash "$AGENT/scripts/check-docs.sh" "$noair" 2>&1)"; rc=$?
{ [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -qi 'air-gap'; } && ok "missing air-gap section is detected" || ko "missing air-gap detection"

echo "== R-06: no secrets, generated credentials, or online-only setup =="
# fresh-clone offline build for the crates (zero external deps -> works offline)
if command -v cargo >/dev/null 2>&1; then
  for r in "$AGENT" "$SDK"; do
    cargo build --quiet --offline --manifest-path "$r/Cargo.toml" >/dev/null 2>&1 \
      && ok "$(basename "$r") builds offline (cargo build --offline)" \
      || ko "$(basename "$r") offline build"
  done
else
  skip "R-06 offline crate build (cargo not available)"
fi
# catalog repo validates offline with no secrets
( cd "$FW" && bash scripts/check-structure.sh >/dev/null 2>&1 ) && ok "sovri-frameworks structure check passes offline" || ko "frameworks offline structure check"
# violation: a committed credential file (.env) is blocked and named
sg="$tmpd/secret-guard"; mkdir -p "$sg"
( cd "$sg" && git init -q && printf 'PLACEHOLDER=replace-me\n' > .env && git add -f .env \
    && out="$(bash "$AGENT/scripts/no-secrets.sh" --staged 2>&1)"; rc=$?
  { [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q '.env'; } && exit 0 || exit 1 ) \
  && ok "staged .env is blocked and named" || ko ".env secret guard"
# violation: a setup step that mints and stores a credential is rejected
mint="$tmpd/setup.md"
printf '## Setup\nRun the helper to generate an API credential and store it in ~/.sovri/cred before building.\n' > "$mint"
bash "$AGENT/scripts/check-offline-setup.sh" "$mint" >/dev/null 2>&1 \
  && ko "generated-credential setup should be rejected" \
  || ok "generated-credential setup is rejected"
# @technical: CI requires no repository secrets
secref=0
for r in "$AGENT" "$SDK" "$FW"; do
  grep -rqE '\$\{\{[^}]*secrets\.' "$r/.github/workflows/" 2>/dev/null && secref=1
done
[ "$secref" -eq 0 ] && ok "no CI workflow references repository secrets" || ko "CI references secrets"

echo ""
echo "================ acceptance summary ================"
printf 'PASS: %d   FAIL: %d\n' "$pass" "$fail"
[ "$fail" -eq 0 ] || exit 1
