# Rule: R-04
@e2e
Feature: The agent runs a placeholder command without external services
  As a Sovri compliance-platform maintainer
  I want sovri-agent to run a placeholder command with no external services
  So that the agent is proven to operate air-gapped from day one

  @nominal
  Scenario: The placeholder command succeeds with no network available
    Given the repository "sovri-agent" has been built
    And no network connectivity is available
    When I run the placeholder command "sovri-agent selftest"
    Then it exits with status 0
    And it prints a status line reporting the agent version

  @technical
  Scenario: The placeholder command needs no environment configuration
    Given the repository "sovri-agent" has been built
    And no environment variables are set beyond the operating-system defaults
    And no network connectivity is available
    When I run the placeholder command "sovri-agent selftest"
    Then it exits with status 0

  @violation
  Scenario: The placeholder command opens no outbound connection
    Given the repository "sovri-agent" has been built
    And outbound network egress is blocked
    When I run the placeholder command "sovri-agent selftest"
    Then it exits with status 0
    And it makes no outbound network connection
