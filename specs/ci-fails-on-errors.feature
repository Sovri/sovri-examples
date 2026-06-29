# Rule: R-02
@e2e
Feature: CI fails on format, lint, test, or build errors
  As a Sovri compliance-platform maintainer
  I want each repository's CI to fail on format, lint, test, or build errors
  So that broken changes cannot merge into the compliance toolchain

  @nominal
  Scenario Outline: A clean Rust crate passes all CI gates
    Given the repository "<crate>" has been scaffolded
    And the working tree is formatted, lint-clean, builds, and all tests pass
    When the CI workflow runs on a pull request
    Then the CI workflow succeeds

    Examples:
      | crate          |
      | sovri-agent    |
      | sovri-sdk-rust |

  @nominal
  Scenario: The catalog repository CI passes when the family structure is intact
    Given the repository "sovri-frameworks" has been scaffolded
    And all required framework family directories are present
    When the CI workflow runs on a pull request
    Then the CI workflow succeeds

  @violation
  Scenario Outline: A Rust crate CI fails when a quality gate is violated
    Given the repository "sovri-sdk-rust" has been scaffolded
    And the working tree has "<defect>"
    When the CI workflow runs on a pull request
    Then the CI workflow fails
    And the failing gate is "<gate>"

    Examples:
      | defect                               | gate   |
      | a file that is not rustfmt-formatted | format |
      | a clippy warning denied as an error  | lint   |
      | a failing unit test                  | test   |
      | a compilation error                  | build  |

  @violation
  Scenario: The catalog repository CI fails when a required family directory is missing
    Given the repository "sovri-frameworks" has been scaffolded
    And the "frameworks/nis2" directory has been deleted
    When the CI workflow runs on a pull request
    Then the CI workflow fails
    And the failing gate is the catalog structure gate

  @technical
  Scenario: Every third-party GitHub Action in CI is pinned by commit SHA
    Given the repository "sovri-agent" has been scaffolded
    When I inspect the CI workflow files
    Then every third-party action reference is pinned to a full 40-character commit SHA
    And no third-party action is referenced by a floating tag
