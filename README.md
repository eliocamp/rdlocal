<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/eliocamp/rhelpi18n/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/eliocamp/rdlocal/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

# Multilingual R Help Pages

The `rdlocal` package supports translation of R help pages. Once installed, R will display
documentation (for example `?function_name`) in the configured language, provided a translation 
module is available. This will work with the HTML documentation displayed by R GUIs like RStudio, 
as well as with text documentation displayed by R in the console.

Translations are distributed as separate **translation modules** that hold the translated 
text for a given package's help pages. rdlocal provides tools to generate a translation module skeleton
from a package's existing `.Rd` files, extracting the translatable strings into YAML files 
that contains the original and translated versions.


This project started at the 2023 R Project Sprint (see 
[this issue](https://github.com/r-devel/r-project-sprint-2023/issues/35) 
for background) and is still experimental.

## For users

Install this package:

``` r
pak::pak("eliocamp/rdlocal")
```

Next install a translation module. 
The [base.es](https://github.com/eliocamp/base.es) package hosts translations for `base::mean()` as an example, install it with:

``` r
pak::pak("eliocamp/base.es")
```

Setting the LANGAUGE environmental variable to "es" will change your R language. 

```r
library(rdlocal)
Sys.setenv(LANGUAGE = "es")
```

Now `base::mean()`'s help page will be displayed in Spanish.


<video style="max-height:640px; min-height: 200px" controls>
  <source src="https://github.com/eliocamp/rdlocal/assets/8617595/be3038dd-ac53-4fa7-a0bf-51a5de9a91bf" type="video/mp4">
</video>


## For translators

First get a copy of the package you want to translate. 

Choose your translation **language** by its [ISO 2-letter code](https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes)
with a regional option using underscore. For example Spanish would be `language = "es"`, and Argentine Spanish would be 
`language = "es_AR"`.

Then use `rdlocal::i18n_module_create()` to create a **lang** translation **module** for that **package**


```r
rdlocal::i18n_module_create(package_path = "path/to/package",
                            language = "lang", 
                            module_name = "package.lang", 
                            module_path = "path/to/module.lang", 
                            )
```

The translation strings are saved into yaml files, one per Rd file of the original package.

You can find them in `path/to/module.lang/inst/translations` with this format:

```yaml
title:
  original: Title in the original language
  translation: ~
```

Where `title` is the section in the documentation, `original` stores the original string and
`translation` will have the translated string. 

Translation modules can be distributed and install from GitHub or R-Universe. 


### Known issues

1. It's not clear that the page is a translation and not the "official" one. 
2. It's not possible to access the original documentation without changing the LANGUAGE environmental variable and opening the help page again. 
3. There are some formatting issues, such as the `...` argument name. 

