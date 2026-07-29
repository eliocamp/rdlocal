# Creates a translation module

Creates a translation module skeleton form a source package with the
translation templates with the original strings and the proper functions
to load translations.

## Usage

``` r
i18n_module_create(
  module_name = NULL,
  language,
  module_path = file.path(".", module_name),
  package_path,
  rstudio_project = TRUE
)
```

## Arguments

- module_name:

  Name of the translation module. It needs to be a valid package name.
  If missing, it will be created as the name of the package.language.

- language:

  Language of the translation module

- module_path:

  Path where the module will be created.

- package_path:

  Path to the package that will be translated.

- rstudio_project:

  Logical indicating whether to create an .Rproj file.
