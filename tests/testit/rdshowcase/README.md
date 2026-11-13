# Multilingual documentation generator for R packages

An R package developed as a demonstration for the Google Summer of Code (GSoC)
project on multilingual R package documentation. It provides a single function,
`submit_proposal()`, whose documentation illustrates dynamic Rd content via
`\Sexpr` macros.

## Installation

Install from source during development:

```r
# From the package root directory
devtools::install()
```

## Usage

```r
library(gsocproposal)

# Returns TRUE if today is on or before 2025-03-31, FALSE otherwise.
submit_proposal()
```

## How the deadline works

The submission deadline is defined in `R/globals.R`:

```r
.pkg_env$deadline <- as.Date("2025-03-31")
```

`submit_proposal()` reads `Sys.Date()` and compares it to
`.pkg_env$deadline`. Because the deadline lives in a package-level environment
rather than inside the function body or in the Rd source, you can update it in
one place without touching documentation or function logic.

## Dynamic documentation

Two `\Sexpr` macros are embedded in the Rd file for `submit_proposal()`:

| Stage   | What it does |
|---------|--------------|
| `install` | Writes the deadline date into the help page at install time. |
| `render`  | Computes how many days remain and inserts the result each time the user opens the help page. |

View the live message with:

```r
?submit_proposal
```

## Running tests

```r
devtools::test()
```

All eight tests cover the Easy (return value correctness), Medium (documentation
presence), and Hard (deadline in environment, Sexpr logic validity) requirements
from the GSoC project brief.

## Package structure

```
gsocproposal/
+-- DESCRIPTION
+-- LICENSE
+-- NAMESPACE
+-- README.md
+-- R/
|   +-- globals.R          # .pkg_env and deadline definition
|   +-- submit_proposal.R  # exported function with Sexpr documentation
+-- man/
|   +-- submit_proposal.Rd # Rd file with stage=install and stage=render Sexpr
+-- tests/
    +-- testthat.R
    +-- testthat/
        +-- helper-gsocproposal.R
        +-- test-submit_proposal.R
```
