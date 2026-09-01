# rd_flatten / to_text behaviour that the runtime depends on.
rd_flatten <- rdlocal:::rd_flatten

flatten <- function(...) {
  f <- tempfile(fileext = ".Rd")
  writeLines(c("\\name{t}", "\\title{t}", "\\description{", ..., "}"), f)
  rd_flatten(tools::parse_Rd(f))$description$original
}

assert("#ifdef / #ifndef nodes flatten without error and keep the condition", {
  (is.character(flatten(
    "Base.",
    "#ifndef windows",
    "UNIX LINE.",
    "#endif",
    "End."
  )))
  (grepl(
    "windows",
    flatten("Base.", "#ifndef windows", "UNIX LINE.", "#endif", "End."),
    fixed = TRUE
  ))
})

assert("a user-defined macro expands exactly once (not doubled)", {
  out <- flatten(
    "\\newcommand{\\gsoc}{Google Summer of Code}",
    "We joined \\gsoc{} in 2026."
  )
  (lengths(regmatches(
    out,
    gregexpr("Google Summer of Code", out, fixed = TRUE)
  )) ==
    1L)
})
