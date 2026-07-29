# Returns matching languages

Returns matching languages

## Usage

``` r
resolve_lang(languages, target_language)
```

## Arguments

- languages:

  a character vector of languages.

- target_language:

  a single character string with the desired language.

## Value

a logical vector of the same length as `languages` indicating which
language is a match for the target_language

## Details

This should take into account the ISO hierarchy. i.e.: if
target_language is "es_AR", then "es" is good, but "es_AR" is better. if
target language is "es", then "es_AR" is also good.

Right now it returns `TRUE` for exact matches only and if there are no
matches, it returns `TRUE` for elements in `language` that have the same
root language as `target_language`. So if `target_language` is
`"es_AR"`, then `"es_UY"`, `"es_ES"` and `"es"` will all return `TRUE`.
