# Rule: R-03
@e2e
Feature: Framework catalog placeholder structure
  As a Sovri compliance-platform maintainer
  I want sovri-frameworks to ship placeholder catalog directories matching the MAT-84 layout
  So that later framework, control, and rule work can land without restructuring the repository

  @nominal
  Scenario Outline: Each initial framework family has a placeholder catalog directory
    Given the repository "sovri-frameworks" has been scaffolded
    When I list the "frameworks/" directory
    Then it contains a directory "<family>"

    Examples:
      | family        |
      | gdpr-eprivacy |
      | iso27001      |
      | nis2          |
      | dora          |
      | ai-act        |
      | custom        |

  @nominal
  Scenario: The catalogs live under the correctly spelled top-level directory
    Given the repository "sovri-frameworks" has been scaffolded
    When I list the repository root
    Then it contains a directory "frameworks"
    And it does not contain a directory "farameworks"

  @nominal
  Scenario: The catalog README documents the per-family layout owned by the later structure ticket
    Given the repository "sovri-frameworks" has been scaffolded
    When I read "frameworks/README.md"
    Then it documents that each family will hold a versioned "framework.yaml"
    And it documents the planned control, rule, and mapping paths for each family
    And it states that the framework content and id naming conventions are delivered by a later ticket

  @technical
  Scenario: Placeholder family directories are tracked by git
    Given the repository "sovri-frameworks" has been scaffolded
    When I inspect the "frameworks/ai-act" directory
    Then it contains a tracked placeholder file so the empty directory is versioned

  @violation
  Scenario: A missing framework family is detected
    Given the repository "sovri-frameworks" has been scaffolded
    And the "frameworks/gdpr-eprivacy" directory is absent
    When the catalog structure check runs
    Then it fails
    And it names the missing family "gdpr-eprivacy"
