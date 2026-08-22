# Read translations from a directory

Reads a translation module's `.yaml` files into the same list structure
the runtime uses.

## Usage

``` r
read_translations(dir = "inst/translations")
```

## Arguments

- dir:

  Directory of translation `.yaml` files (a module's
  `inst/translations`).

## Value

A named list of translations, one element per help topic.
