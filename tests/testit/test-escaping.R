# {ISEXPR_*} needs no author escaping in normal Rd; only \{ISEXPR_*\} produces a
# literal, escaped in stored strings as {{ISEXPR_*}}.
mf <- rdlocal:::match_and_fill
rd_flatten <- rdlocal:::rd_flatten

flatten <- function(body) {
  f <- tempfile(fileext = ".Rd")
  writeLines(c("\\name{t}", "\\title{t}", "\\description{", body, "}"), f)
  trimws(rd_flatten(tools::parse_Rd(f))$description$original)
}

assert("ordinary prose braces are stripped -> no literal token, no escaping needed", {
  (!grepl("{ISEXPR_0}", flatten("Here: {ISEXPR_0}."), fixed = TRUE))
  (grepl("ISEXPR_0", flatten("Here: {ISEXPR_0}."), fixed = TRUE))
})

assert("Rd-escaped braces \\{ \\} are the only way to emit a literal {ISEXPR_0}", {
  (grepl("{ISEXPR_0}", flatten("Here: \\{ISEXPR_0\\}."), fixed = TRUE))
})

assert("a raw literal in a scaffold is mis-read (the exotic collision)", {
  (grepl(
    "X",
    mf("Here: X.", "Here: {ISEXPR_0}.", "Aqui: {ISEXPR_0}.")$text,
    fixed = TRUE
  ))
})

assert("doubling the braces {{ISEXPR_0}} escapes the literal", {
  (mf("Here: {ISEXPR_0}.", "Here: {{ISEXPR_0}}.", "Aqui: {{ISEXPR_0}}.")$text ==
    "Aqui: {ISEXPR_0}.")
})
