# Reading help in your language

This guide is for **R users** who want to read documentation in their
own language.

## The short version

There are 2 steps to get documentation in your language.

1.  Install a translation module (once per machine)
2.  Load rdlocal and set R’s language (once per session)

## The longer version

### Translation modules.

The rdlocal package adds support for **translation modules** that
provide translated documentation for a package to a particular language.
Translation modules are made by the community and installed like regular
packages.

For this vignette, we are going to use a sample package prepared as
demonstration.

``` r

# Install the gsocproposal package
remotes::install_github("adit-0132/multilingual-docs") 
```

There is a translation module for this package to Spanish in the
`spanish` branch.

``` r

# Install the translation module
remotes::install_github("adit-0132/multilingual-docs@spanish")
```

You can install as many translation modules as you want. Each
translation module translates one package into one language. If no
translation module exists for a particular package or language, then the
original package help will be shown as normal.

The gsocproposal package has a `greet` object with sample documentation

``` r

?gsocproposal::greet
```

### Loading rdlocal and setting langauge

To enable translated documentation you need to load the rdlocal package.
And to change you R language to Spanish, you need to set the language.

``` r

library(rdlocal)
Sys.setLanguage("es")
```

This also switches the language of R’s own messages, warnings and
errors, wherever a localisation for them exists.

Now the documentation will be in Spanish

``` r

?gsocproposal::greet
```

Language codes are two-letter codes optionally followed by a two-letter
contry code separated by underscore. Some examples are:

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

The language change applies to the current session; New sessions will
revert to the default language. To make it permanent, you need to add it
to `.Rprofile`:

Run

``` r

usethis::edit_r_profile()   # add:  LANGUAGE=es
```

And add this:

``` r

if (requireNamespace("rdlocal", quietly = TRUE)) {
  library(rdlocal)
  Sys.setLanguage("es")
}
```

To see the help page in the original language, change your language to a
language with no translation installed (the default is `"en"`):

``` r

Sys.setLanguage("en")
?gsocproposal::greet
```

### Troubleshooting

- **Still English?** Check that `Sys.getenv("LANGUAGE")` is set and that
  [`library(rdlocal)`](https://eliocamp.github.io/rdlocal/) is loaded.
- **Some sections translated, some not?** Sections with incomplete or
  outdated translations are shown in the original language.
- **List what translations you have:**

``` r

ip <- installed.packages(fields = c("Translates", "Language"))
ip[!is.na(ip[, "Translates"]), c("Package", "Translates", "Language")]
```
