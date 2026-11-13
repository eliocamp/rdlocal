#' Integrated showcase of Rd features
#'
#' @description
#' Checks whether the current system date falls on or before the package
#' submission deadline. Returns \code{TRUE} if submissions are still open and
#' \code{FALSE} once the deadline has passed.
#'
#' The deadline is not hard-coded in the documentation. It is read from the
#' package environment \pkgenv{} at \strong{install time}:
#'
#' Deadline: \Sexpr[results=text,stage=install]{
#'   as.character(gsocproposal:::.pkg_env$deadline)
#' }
#'
#' When you view this help page, the following message is computed \emph{live} at
#' \strong{render time}:
#'
#' \Sexpr[results=text,stage=render]{
#'   dl        <- gsocproposal:::.pkg_env$deadline
#'   days_left <- as.integer(dl - Sys.Date())
#'   if (days_left > 0) {
#'     paste0("The deadline is in ", days_left, " day(s).")
#'   } else if (days_left == 0) {
#'     "The deadline is today."
#'   } else {
#'     "The deadline has passed, try next year!"
#'   }
#' }
#'
#' @details
#' This section showcases ordinary inline markup so we can see it render and,
#' later, translate.
#'
#' \subsection{Inline text markup}{
#' Emphasis with \emph{emph}, \strong{strong}, and \bold{bold}. Code and objects:
#' \code{submit_proposal()}, a variable \var{deadline}, a package \pkg{gsocproposal},
#' a file \file{R/globals.R}, an option \option{--no-save}, an environment variable
#' \env{LANGUAGE}, a command \command{R CMD INSTALL}, and a keystroke \kbd{Ctrl+C}.
#' Quotations: \sQuote{single} and \dQuote{double}; a definition \dfn{Sexpr}; an
#' acronym \acronym{CRAN}; a citation \cite{R Core Team}; verbatim \verb{#ifdef};
#' literal sample \samp{x <- 1}. The \R{} language. A non-ASCII fallback:
#' \enc{Björk}{Bjork}. A literal percent sign: 50\%. A user-defined macro that
#' takes an argument: \deadlineNote{2025-03-31}
#' }
#'
#' \subsection{Lists}{
#' An itemized list:
#' \itemize{
#'   \item Build stage runs at \command{R CMD build}.
#'   \item Install stage runs at \command{R CMD INSTALL}.
#'   \item Render stage runs every time \code{?submit_proposal} is opened.
#' }
#' An enumerated list:
#' \enumerate{
#'   \item First.
#'   \item Second.
#' }
#' A described list:
#' \describe{
#'   \item{build}{Baked into the source tarball.}
#'   \item{install}{Baked into the installed \file{.rdb} database.}
#'   \item{render}{Evaluated live on every help lookup.}
#' }
#' }
#'
#' \subsection{A table}{
#' \tabular{lll}{
#'   \strong{Stage}   \tab \strong{Runs during}    \tab \strong{Live in .rdb?} \cr
#'   build            \tab R CMD build             \tab no                      \cr
#'   install          \tab R CMD INSTALL           \tab no (baked to text)      \cr
#'   render           \tab every help lookup       \tab yes                     \cr
#' }
#' }
#'
#' \subsection{Math}{
#' Inline math \eqn{d = t_1 - t_0}{d = t1 - t0} and display math:
#' \deqn{\textrm{open} \iff \textrm{Sys.Date()} \le \textrm{deadline}.}{open iff Sys.Date() <= deadline.}
#' }
#'
#' \subsection{Platform conditionals (#ifdef / #ifndef)}{
#' The lines below are preprocessor-style conditionals. The \verb{#} must be the
#' first character on its line, the block must be wholly nested inside a macro, and
#' each block is closed by \verb{#endif} (parseRd.pdf sections 2.3 and 3).
#' #ifdef windows
#' This paragraph is included \strong{only on Windows}.
#' #endif
#' #ifndef windows
#' This paragraph is included on \strong{everything except Windows} (Unix, macOS).
#' #endif
#' }
#'
#' @section Sexpr stage and results showcase:
#' Every \code{\link[=submit_proposal]{Sexpr}} variant in one place. \code{stage}
#' controls \emph{when} the code runs; \code{results} controls \emph{how} the value
#' is inserted.
#'
#' \describe{
#'   \item{build}{\Sexpr[results=text,stage=build]{ "[evaluated at build stage]" }}
#'   \item{install (default stage)}{\Sexpr[results=text]{ paste0("R ", getRversion()) }}
#'   \item{render}{\Sexpr[results=text,stage=render]{ format(Sys.Date()) }}
#' }
#'
#' \code{results=verbatim} prints as if at the console:
#' \Sexpr[results=verbatim,stage=render]{ 1 + 1 }
#'
#' \code{echo=TRUE} echoes the source too:
#' \Sexpr[echo=TRUE,results=verbatim,stage=render]{ x <- 40 + 2; x }
#'
#' \code{results=rd} treats the returned string as Rd markup and splices it in
#' place: \Sexpr[results=rd,stage=render]{ "\\\\emph{(this fragment was generated and re-parsed as Rd)}" }
#'
#' \code{results=hide} evaluates for its side effect and inserts nothing:\Sexpr[results=hide,stage=render]{ invisible(NULL) }
#'
#' @returns
#' A single logical value. \code{TRUE} if \code{Sys.Date()} is less than or equal
#' to the \gsoc{} deadline stored in \pkgenv{}; \code{FALSE} otherwise.
#'
#' @note
#' Output-format conditionals choose content per renderer. \ifelse{html}{HTML
#' output}{\ifelse{latex}{LaTeX output}{plain-text output}} is shown here.
#' A raw passthrough for HTML only: \if{html}{\out{<strong>raw HTML</strong>}}\if{text}{(no raw HTML in text mode)}.
#'
#' @references
#' R Core Team. \emph{Writing R Extensions}. \url{https://cran.r-project.org/doc/manuals/R-exts.html}.
#' Murdoch, D. (2010). \href{https://developer.r-project.org/parseRd.pdf}{Parsing Rd files}.
#'
#' @seealso
#' \code{\link{Sys.Date}} for the system date, \code{\link[base]{as.Date}} for
#' date parsing, and \code{\link[=submit_proposal]{this page}} for a self link.
#'
#' @examples
#' # Check whether the submission window is currently open.
#' submit_proposal()
#'
#' \dontrun{
#' # Not run during checks (e.g. needs interaction or a network):
#' browseURL("https://summerofcode.withgoogle.com")
#' }
#'
#' \donttest{
#' # Run interactively but skipped on CRAN's timing-sensitive checks:
#' Sys.sleep(0)
#' }
#'
#' \dontshow{
#' # Hidden setup that still runs (useful for test invariants):
#' stopifnot(is.logical(submit_proposal()))
#' }
#' @export
submit_proposal <- function() {
  Sys.Date() <= .pkg_env$deadline
}
