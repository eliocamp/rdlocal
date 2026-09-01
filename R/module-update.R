#' Update a translation module to a newer version of its package
#'
#' Re-syncs an existing translation module (made with [i18n_module_create()])
#' against a newer version of the package it translates. A fresh scaffold is
#' generated from the new source and merged into the existing module, per section
#' and per `\arguments` item:
#'
#' * **unchanged** original -> the existing translation is kept;
#' * **changed** original -> the old translation is kept but the section is
#'   flagged `fuzzy: yes`, with the previous text stored in `previous_original:`
#'   so the translator can see what changed and edit rather than redo;
#' * **new** section -> added with an empty `translation:`;
#' * **removed** section -> dropped.
#'
#' At runtime a `fuzzy` section still shows its (possibly out-of-date) translation,
#' with a small note revealing the current original. The translator resolves it by
#' updating the `translation:` and deleting the `fuzzy:`/`previous_original:`
#' lines; `i18n_module_update()` never clears the flag itself.
#'
#' The module is updated **in place** (it is a package, so review the change with
#' version control); `man_original/` and the `Translates:` version are refreshed.
#' Other DESCRIPTION fields (title, author, ...) are left untouched.
#'
#' @param module_path Path to the existing translation module.
#' @param package_path Path to the new version of the package source.
#' @param dry_run If `TRUE`, report what would change without writing anything.
#'
#' @return (invisibly) a list of counts: `unchanged`, `fuzzy`, `new`, `dropped`.
#' @seealso [i18n_module_create()]
#' @export
i18n_module_update <- function(module_path, package_path, dry_run = FALSE) {
  old_tdir <- file.path(module_path, "inst", "translations")
  if (!dir.exists(old_tdir)) {
    stop(
      module_path,
      " does not look like a translation module (no inst/translations/)"
    )
  }

  package <- get_package_name(package_path)
  new_version <- get_package_version(package_path)

  # Regenerate a fresh skeleton from the new source into a throwaway module. Its
  # own fallback/omission warning is captured and surfaced in the update report.
  tmp_module <- file.path(tempfile("i18nupd"), paste0(package, ".new"))
  regen_note <- NULL
  withCallingHandlers(
    i18n_module_create(
      package_path,
      language = "und",
      module_name = paste0(package, ".und"),
      module_path = tmp_module,
      rstudio_project = FALSE
    ),
    warning = function(w) {
      regen_note <<- conditionMessage(w)
      invokeRestart("muffleWarning")
    }
  )
  new_tdir <- file.path(tmp_module, "inst", "translations")

  new_files <- list.files(new_tdir, pattern = "\\.yaml$")
  old_files <- list.files(old_tdir, pattern = "\\.yaml$")

  total <- list(unchanged = 0L, fuzzy = 0L, new = 0L, dropped = 0L)
  fuzzy_topics <- new_topics <- dropped_topics <- character(0)
  merged <- list()

  for (f in intersect(new_files, old_files)) {
    c1 <- new.env()
    c1$unchanged <- 0L
    c1$fuzzy <- 0L
    c1$new <- 0L
    c1$dropped <- 0L
    merged[[f]] <- merge_topic(
      yaml::read_yaml(file.path(old_tdir, f)),
      yaml::read_yaml(file.path(new_tdir, f)),
      c1
    )
    for (k in names(total)) {
      total[[k]] <- total[[k]] + c1[[k]]
    }
    if (c1$fuzzy) {
      fuzzy_topics <- c(fuzzy_topics, f)
    }
    if (c1$new) new_topics <- c(new_topics, f)
  }
  for (f in setdiff(new_files, old_files)) {
    merged[[f]] <- yaml::read_yaml(file.path(new_tdir, f))
    total$new <- total$new + count_leaves_topic(merged[[f]])
    new_topics <- c(new_topics, f)
  }
  for (f in setdiff(old_files, new_files)) {
    total$dropped <- total$dropped +
      count_leaves_topic(yaml::read_yaml(file.path(old_tdir, f)))
    dropped_topics <- c(dropped_topics, f)
  }

  report_update(
    total,
    fuzzy_topics,
    new_topics,
    dropped_topics,
    regen_note,
    dry_run
  )

  if (!dry_run) {
    mdir <- file.path(module_path, "man_original")
    for (f in names(merged)) {
      yaml::write_yaml(merged[[f]], file.path(old_tdir, f))
    }
    for (f in setdiff(old_files, new_files)) {
      unlink(file.path(old_tdir, f))
      unlink(file.path(mdir, sub("\\.yaml$", ".Rd", f)))
    }
    src_mdir <- file.path(tmp_module, "man_original")
    if (dir.exists(src_mdir)) {
      file.copy(list.files(src_mdir, full.names = TRUE), mdir, overwrite = TRUE)
    }
    bump_translates(module_path, package, new_version)
  }

  invisible(total)
}

# Merge one topic's stored translation (old) with a freshly generated one (new).
# Non-section keys (needs_review, untranslatable) are carried from `new`.
merge_topic <- function(old, new, counts) {
  is_section <- function(x) is.list(x)
  out <- new[!vapply(new, is_section, logical(1))] # meta keys, from new
  new_secs <- names(new)[vapply(new, is_section, logical(1))]
  old_secs <- names(old)[vapply(old, is_section, logical(1))]
  for (sec in new_secs) {
    out[[sec]] <- merge_node(old[[sec]], new[[sec]], counts)
  }
  for (sec in setdiff(old_secs, new_secs)) {
    counts$dropped <- counts$dropped + count_leaves(old[[sec]])
  }
  out
}

# Merge one node: a simple section (has $original) or an itemlist (\arguments).
merge_node <- function(old, new, counts) {
  if (is.character(new$original)) {
    if (is.null(old) || !is.character(old$original)) {
      # brand new (or changed shape)
      counts$new <- counts$new + 1L
      return(new)
    }
    if (identical(old$original, new$original)) {
      # unchanged: keep translation
      counts$unchanged <- counts$unchanged + 1L
      old$spans <- new$spans # refresh example values
      return(old)
    }
    if (is.null(old$translation)) {
      # changed but never translated
      counts$unchanged <- counts$unchanged + 1L
      return(new)
    }
    counts$fuzzy <- counts$fuzzy + 1L # changed, has a translation -> fuzzy
    new$translation <- old$translation
    new$previous_original <- old$original
    new$fuzzy <- TRUE
    if (!is.null(old$ifdef)) {
      new$ifdef <- old$ifdef
    }
    return(new)
  }
  out <- list() # itemlist: merge per item name
  for (nm in names(new)) {
    out[[nm]] <- merge_node(old[[nm]], new[[nm]], counts)
  }
  for (nm in setdiff(names(old), names(new))) {
    counts$dropped <- counts$dropped + count_leaves(old[[nm]])
  }
  out
}

# Count translatable leaves (simple sections / argument items) in a node/topic.
count_leaves <- function(node) {
  if (!is.list(node)) {
    return(0L)
  } # meta (needs_review, untranslatable)
  if (is.character(node$original)) {
    return(1L)
  }
  sum(vapply(node, count_leaves, integer(1)))
}
count_leaves_topic <- function(topic) {
  sum(vapply(topic, count_leaves, integer(1)))
}

report_update <- function(
  total,
  fuzzy_topics,
  new_topics,
  dropped_topics,
  regen_note,
  dry_run
) {
  message(
    if (dry_run) {
      "i18n_module_update() (dry run) would change:"
    } else {
      "i18n_module_update():"
    }
  )
  message(sprintf(
    "  %d unchanged  |  %d fuzzy  |  %d new  |  %d dropped",
    total$unchanged,
    total$fuzzy,
    total$new,
    total$dropped
  ))
  listing <- function(label, x) {
    if (length(x)) {
      message("  ", label, ": ", paste(sub("\\.yaml$", "", x), collapse = ", "))
    }
  }
  listing("fuzzy", fuzzy_topics)
  listing("new", new_topics)
  listing("dropped", dropped_topics)
  if (total$fuzzy) {
    message(
      "  -> review each fuzzy section, then delete its 'fuzzy:' and 'previous_original:' lines"
    )
  }
  if (!is.null(regen_note)) {
    message("  note (from the new source): ", regen_note)
  }
}

# Update only the Translates version in the module DESCRIPTION, leaving every
# other field (title, author, ...) as the translator left it.
bump_translates <- function(module_path, package, version) {
  dcf <- file.path(module_path, "DESCRIPTION")
  lines <- readLines(dcf)
  i <- grep("^Translates:", lines)
  if (length(i)) {
    lines[i[1]] <- paste0("Translates: ", package, " (== ", version, ")")
  }
  writeLines(lines, dcf)
}
