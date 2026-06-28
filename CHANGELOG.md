# Changelog

All notable changes to this project are documented in this file. The format is
based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- Offline cross-repository acceptance suite (`tests/acceptance.sh`) verifying the
  MAT-81 rules R-01..R-06 across sovri-agent, sovri-sdk-rust, and
  sovri-frameworks, mirrored from the Gherkin features under `specs/`.
- E2E CI workflow with SHA-pinned actions, Apache-2.0 licensing. Scaffolds MAT-81.
