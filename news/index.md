# Changelog

## rhelpi18n 0.0.0.9000

- [`i18n_module_create()`](https://eliocamp.github.io/rhelpi18n/reference/i18n_module_create.md)
  builds a translation-module skeleton from a package’s help pages,
  replacing dynamic install/build `\Sexpr` and `#ifdef` spans with
  `{ISEXPR_i}` placeholders so a translation keeps matching the
  installed help across reinstalls.
- [`i18n_module_update()`](https://eliocamp.github.io/rhelpi18n/reference/i18n_module_update.md)
  re-syncs a translation module against a newer version of its package:
  unchanged translations are kept, changed sections are flagged `fuzzy`
  for review, new sections are added, and removed ones are dropped.
- Help pages are shown in the reader’s language, with install- and
  build-time `\Sexpr` values filled in from the reader’s own
  installation.
- Added
  [`read_translations()`](https://eliocamp.github.io/rhelpi18n/reference/read_translations.md)
  (#14, thanks @maelle).
