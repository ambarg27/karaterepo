Feature: self-contained count (no HTTP)
  Scenario Outline: row <n>
    * def n = <n>
    * assert n > 0
    Examples:
      | n |
      | 1 |
      | 2 |
      | 3 |
