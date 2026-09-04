# Create a translation module from a local source package

Creates a translation module from a source package. The `original`
strings are *scaffolds*: dynamic install/build `\Sexpr` (and
`#ifdef`/`#ifndef`) spans are replaced by `{ISEXPR_i}` placeholders, so
a human's translation keeps matching the installed help across
reinstalls (an install-stage `\Sexpr` bakes a different value each
install, which a plain exact-string template can never match). The
translator fills in the `translation:` fields and leaves the
`{ISEXPR_i}` tokens in place. Each section also carries a `spans:` map
showing an example of what each token held at generation time (the real
value differs per install), so the translator knows what a `{ISEXPR_i}`
stands for.

## Usage

``` r
i18n_module_create(
  package_path,
  language,
  module_name = NULL,
  module_path = file.path(".", module_name),
  rstudio_project = TRUE,
  overwrite = FALSE
)
```

## Arguments

- package_path:

  Path to the local source package to translate.

- language:

  Language code, e.g. `"es"`.

- module_name:

  Module package name. Defaults to `<package>.<language>`, with
  non-alphanumerics in `language` collapsed to `"."` (so `"en-GB"` gives
  `pkg.en.GB`); the real tag is kept in the module's `Language:` field.

- module_path:

  Directory to create the module in.

- rstudio_project:

  Whether to create an `.Rproj` file.

- overwrite:

  If `TRUE`, delete an existing module at `module_path` before creating
  it. Intended for development, when the same module is regenerated
  repeatedly.

## Value

(invisibly) the module path.

## Details

Building the scaffolds needs both the *source* Rd (dynamic nodes still
live) and the *baked* Rd (values resolved). The source is taken from
`package_path`; the baked tree is obtained by installing that source
into a temporary library and reading its `Rd_db`.

If a topic cannot be scaffolded because its source and installed help do
not align, it falls back to a plain template (the flattened source, no
placeholders) marked `needs_review: yes`. Topics missing from the
installed help, or whose source cannot be parsed, are omitted. Either
way the affected topics are listed in a
[`warning()`](https://rdrr.io/r/base/warning.html), so the skeleton is
never silently left incomplete.
