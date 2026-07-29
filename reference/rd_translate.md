# Translates an Rd object

Takes an object returned by `[tools::parse_Rd]` and
`utils::.getHelpfile()` and translates the strings.

## Usage

``` r
rd_translate(Rd, translation)
```

## Arguments

- Rd:

  Rd object

- translation:

  a flattened rd object returned by `[rd_flatten]` or, more likely, by
  `[rd_flat_read]`.

## Value

an Rd object with translated strings.
