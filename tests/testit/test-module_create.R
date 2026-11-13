showcase_es <- "rdshowcase.es"

unlink(showcase_es, recursive = TRUE)

i18n_module_create(
  package_path = "rdshowcase",
  language = "es",
  module_name = "rdshowcase.es"
)

