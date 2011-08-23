Feature: Cartridge Dependency Resolution
  As a developer
  I need to be able to resolve dependencies and map features to dependencies
  So that I can determine what needs to be set up when processing a descriptor

  Scenario: Check missing cartridge
    Given an accepted node 
    And there are no cartridges installed
    When I check the presence of the php cartridge
    Then I find that the php cartridge is not present

  Scenario: Check present cartridge
    Given an accepted node 
    And there are no cartridges installed
    When I check the presence of the php cartridge
    Then I find that the php cartridge is present

  Scenario: Check simple dependency resolution
    Given an accepted node 
    And there are no cartridges installed
    And a yum repository
    And the php package is available in the yum repository
    When I ask what package provides the php feature
    Then I am given the name of the php package

  Scenario: Install dependency
    Given an accepted node 
    And there are no cartridges installed
    And a yum repository
    And the php package is available in the yum repository
    When I request the php cartridge
    Then I find that the php cartridge is present
