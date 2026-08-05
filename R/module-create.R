get_package_name <- function(package_path) {
  description_file <- file.path(package_path, "DESCRIPTION")
  read.dcf(description_file, fields = "Package")[[1]]
}

get_package_version <- function(package_path) {
  description_file <- file.path(package_path, "DESCRIPTION")
  read.dcf(description_file, fields = "Version")[[1]]
}

copy_pkg_template <- function(path, rstudio_project = TRUE) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)

  empty <- length(list.files(path)) == 0
  if (!empty) {
    stop("Path to module exists and it's not empty.")
  }

  skeleton <- system.file("extdata", "translation_skeleton", package = "rhelpi18n") |>
    list.files(full.names = TRUE) |>
    file.copy(path, recursive = TRUE)

  if (is.null(rstudio_project)) {
    file.remove(file.path(path, "skeleton.Rproj"))
  } else {
    file.rename(file.path(path, "skeleton.Rproj"),
                file.path(path, paste0(rstudio_project, ".Rproj")))
  }
  return(path)
}


modify_description <- function(path, module_name, package, version, language) {
  description_file <- file.path(path, "DESCRIPTION")
  description_template <- paste0(readLines(description_file), collapse = "\n")

  description_text <- whisker::whisker.render(description_template, data = list(
    module_name = module_name,
    package_version = paste0(package, " (== ", version, ")"),
    language = language
  ))
  writeLines(description_text, description_file)
}

# from usethis:::valid_package_name
valid_package_name <- function (x) {
  grepl("^[a-zA-Z][a-zA-Z0-9.]+$", x) && !grepl("\\.$", x)
}


