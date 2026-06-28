# Rule: R-06
@e2e
Feature: No secrets, generated credentials, or online-only setup
  As a Sovri compliance-platform maintainer
  I want the repositories to build and run with no secrets and no online-only setup
  So that the toolchain works in an air-gapped, credential-free environment

  @nominal
  Scenario Outline: A fresh crate clone builds offline with no secrets configured
    Given a fresh clone of "<crate>"
    And no secrets or credentials are configured
    And no network connectivity is available
    When I run "cargo build"
    Then it exits with status 0

    Examples:
      | crate          |
      | sovri-agent    |
      | sovri-sdk-rust |

  @nominal
  Scenario: The agent placeholder command runs offline with no secrets
    Given a fresh clone of "sovri-agent" has been built offline
    And no secrets or credentials are configured
    When I run the placeholder command "sovri-agent selftest"
    Then it exits with status 0

  @nominal
  Scenario: The catalog repository validates offline with no secrets
    Given a fresh clone of "sovri-frameworks"
    And no secrets or credentials are configured
    And no network connectivity is available
    When I run its documented catalog structure check
    Then it exits with status 0

  @violation
  Scenario: A committed credential file is rejected
    Given the repository "sovri-agent" has been scaffolded
    And a file ".env" containing a token is staged for commit
    When the secret guard runs
    Then it blocks the commit
    And it names the offending file ".env"

  @violation
  Scenario: A setup step that mints and stores a credential is rejected
    Given the repository "sovri-agent" has been scaffolded
    And the build or run instructions add a step that generates an API token and stores it on disk
    When the offline-setup check runs
    Then it fails
    And it reports that building or running must not require a generated credential

  @technical
  Scenario: CI does not require production secrets
    Given the repository "sovri-agent" has been scaffolded
    When the CI workflow runs on a pull request from a fork with no repository secrets
    Then the CI workflow succeeds
