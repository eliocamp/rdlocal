# Creates templates for translation

Grabs .Rd files and creates yaml templates to then translate.

## Usage

``` r
i18n_translation_templates(rd_files, folder, macros = NULL)
```

## Arguments

- rd_files:

  character vector of rd files.

- folder:

  folder where to save the templates. Will be created if it doesn't
  exist.

- macros:

  a set of macros definitions.

## Examples

``` r
rd_files <- system.file("extdata", "periodic.Rd", package = "rdlocal")
template_folder <- tempdir()
i18n_translation_templates(rd_files, template_folder)
#> /home/runner/work/_temp/Library/rdlocal/extdata/periodic.Rd 
#>                             "/tmp/RtmpY1p00N/periodic.yaml" 
```
