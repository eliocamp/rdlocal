# Update a translation module to a newer version of its package

Re-syncs an existing translation module (made with
[`i18n_module_create()`](https://eliocamp.github.io/rdlocal/reference/i18n_module_create.md))
against a newer version of the package it translates. A fresh scaffold
is generated from the new source and merged into the existing module,
per section and per `\arguments` item:

## Usage

``` r
i18n_module_update(module_path, package_path, dry_run = FALSE)
```

## Arguments

- module_path:

  Path to the existing translation module.

- package_path:

  Path to the new version of the package source.

- dry_run:

  If `TRUE`, report what would change without writing anything.

## Value

(invisibly) a list of counts: `unchanged`, `fuzzy`, `new`, `dropped`.

## Details

- **unchanged** original -\> the existing translation is kept;

- **changed** original -\> the old translation is kept but the section
  is flagged `fuzzy: yes`, with the previous text stored in
  `previous_original:` so the translator can see what changed and edit
  rather than redo;

- **new** section -\> added with an empty `translation:`;

- **removed** section -\> dropped.

At runtime a `fuzzy` section still shows its (possibly out-of-date)
translation, with a small note revealing the current original. The
translator resolves it by updating the `translation:` and deleting the
`fuzzy:`/`previous_original:` lines; `i18n_module_update()` never clears
the flag itself.

The module is updated **in place** (it is a package, so review the
change with version control); `man_original/` and the `Translates:`
version are refreshed. Other DESCRIPTION fields (title, author, ...) are
left untouched.

## See also

[`i18n_module_create()`](https://eliocamp.github.io/rdlocal/reference/i18n_module_create.md)
