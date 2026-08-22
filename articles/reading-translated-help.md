# Reading help in your language

This guide is for **R users** who would rather read documentation in
their own language. Nothing here changes how your code runs — only what
`?function` shows.

## The whole thing

``` r

remotes::install_github("SOMEONE/gsocproposal.es")   # 1. install a translation
library(rdlocal); Sys.setLanguage("es"); ?greet    # 2. load, pick a language, read
```

The rest explains each step.

## 1. Install the package and a translation

``` r

install.packages("gsocproposal")                    # the package (however you normally would)
remotes::install_github("SOMEONE/gsocproposal.es")  # a Spanish translation module
```

Translations ship as their own small packages, usually named
`<package>.<language>`. Install as many as you like — one per language,
or for different packages; they don’t conflict. If none exists for your
package and language, the original package help will be shown as normal.

## 2. Choose your language

Set the help language with base R’s
[`Sys.setLanguage()`](https://rdrr.io/r/base/gettext.html). It applies
to the current session only — restarting R reverts it — so to make it
permanent add it to `.Renviron`:

``` r

# this session only:
Sys.setLanguage("es")

# permanently: add a line to ~/.Renviron
usethis::edit_r_environ()   # add:  LANGUAGE=es
```

This also switches the language of R’s own messages, warnings and
errors, wherever a localisation for them exists.

| Language             | `LANGUAGE` |
|----------------------|------------|
| Spanish              | `es`       |
| French               | `fr`       |
| Brazilian Portuguese | `pt_BR`    |
| Simplified Chinese   | `zh_CN`    |
| Traditional Chinese  | `zh_TW`    |
| English              | `en`       |

Codes follow gettext’s `ll_CC` form — a lowercase [ISO 639 language
code](https://www.gnu.org/software/gettext/manual/html_node/Usual-Language-Codes.html)
(or a [three-letter
code](https://www.gnu.org/software/gettext/manual/html_node/Rare-Language-Codes.html)
for rarer languages), optionally plus an uppercase [ISO 3166 territory
code](https://www.gnu.org/software/gettext/manual/html_node/Country-Codes.html).
So use an **underscore, not a hyphen** (`zh_CN`, not `zh-CN`), and note
that `zh_CN` and `zh_TW` are treated as different languages.

## 3. Load the engine and read

Load **rdlocal** in every R session where you want translated help — it
is what makes `?` look for a translation:

``` r

library(rdlocal)
library(gsocproposal)
?greet
```

The help pane now shows the translated page, with any version- or
date-specific bits filled in with the real, current value. Untranslated
sections are shown in the original language.

## Seeing the original English again

To see the help page in the original language, change your language to a
language with no translation installed (the default is `"en"`):

``` r

Sys.setLanguage("en"); ?greet
```

## Switching languages

``` r

Sys.setLanguage("fr"); ?greet   # French
```

No reinstall needed to switch — just change the language.

## Troubleshooting

- **Still English?** Check that `Sys.getenv("LANGUAGE")` is set and that
  [`library(rdlocal)`](https://eliocamp.github.io/rdlocal/) is loaded.
- **Some sections translated, some not?** That translation is
  incomplete, or the package was updated since it was written.
- **List what translations you have:**

``` r

ip <- installed.packages(fields = c("Translates", "Language"))
ip[!is.na(ip[, "Translates"]), c("Package", "Translates", "Language")]
```
