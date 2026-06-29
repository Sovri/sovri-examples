# Rule: R-05
@e2e
Feature: Repository docs explain Open Core boundaries and air-gap assumptions
  As a Sovri compliance-platform maintainer
  I want each repository's docs to explain the Community/Open Core boundary and the air-gap assumptions
  So that contributors and operators understand what is public and that execution stays offline

  @nominal
  Scenario Outline: Each repository README documents the boundary and air-gap sections
    Given the repository "<repo>" has been scaffolded
    When I read its README
    Then it has a section explaining the Community and Open Core boundary
    And it states the repository license is Apache-2.0
    And it has a section explaining the air-gap and offline-execution assumptions

    Examples:
      | repo             |
      | sovri-agent      |
      | sovri-frameworks |
      | sovri-sdk-rust   |

  @nominal
  Scenario: The air-gap section states framework text comes from versioned catalogs, not an LLM
    Given the repository "sovri-frameworks" has been scaffolded
    When I read the air-gap section of its README
    Then it states that official framework text and source URLs come from versioned catalogs
    And it states that no external API is required during execution

  @violation
  Scenario Outline: A README missing a required section is detected
    Given the repository "sovri-agent" has been scaffolded
    And its README has no "<section>" section
    When the documentation check runs
    Then it fails
    And it reports the missing "<section>" section

    Examples:
      | section                 |
      | air-gap                 |
      | Community and Open Core |
