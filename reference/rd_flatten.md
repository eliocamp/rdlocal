# Reformats the Rd structure

The Rd structure returned by
[`tools::parse_Rd`](https://rdrr.io/r/tools/parse_Rd.html) and
`utils::.getHelpfile()` can to nested and is not ideal for translation.
`rd_flatten` "flattens" that structure into a simpler list and
`rd_unflatten` goes back to the original structure.

## Usage

``` r
rd_flatten(
  Rd,
  untranslatable = c("alias", "name", "keyword", "concept", "usage")
)

rd_unflatten(rd_flat)
```

## Arguments

- Rd:

  a parsed Rd file returned by
  [`tools::parse_Rd`](https://rdrr.io/r/tools/parse_Rd.html) or
  `utils::.getHelpfile()`.

- untranslatable:

  character vector of fields that should not be translated.

- rd_flat:

  a flattened Rd file.
