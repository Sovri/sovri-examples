# Rule: R-01
@e2e
Feature: Documented build, test, and lint commands per repository
  As a Sovri compliance-platform maintainer
  I want every scaffolded repository to document its build, test, and lint commands
  So that a contributor can reproduce the CI gates locally without reverse-engineering the workflow

  @nominal
  Scenario Outline: A Rust crate documents its build, test, and lint commands
    Given the repository "<repo>" has been scaffolded
    When I read the "Development" section of its README
    Then it documents the build command "cargo build"
    And it documents the test command "cargo test"
    And it documents the lint command "cargo fmt --check && cargo clippy --all-targets -- -D warnings"

    Examples:
      | repo           |
      | sovri-agent    |
      | sovri-sdk-rust |

  @nominal
  Scenario: The catalog repository documents how to lint and validate catalogs
    Given the repository "sovri-frameworks" has been scaffolded
    When I read the "Development" section of its README
    Then it documents a command that lints the catalog YAML files
    And it documents a command that validates the catalog structure offline

  @violation
  Scenario: A README that omits a required command is detected as non-compliant
    Given the repository "sovri-sdk-rust" has been scaffolded
    And its README "Development" section lists only the build and test commands
    When the documented-commands check inspects the README
    Then the check fails
    And it names the missing lint command
