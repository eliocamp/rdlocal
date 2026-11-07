% Stress fixture (task 2): multi-line install \Sexpr, with and without braces in code.
\name{stress_multiline-expression}
\alias{stress_multiline-expression}
\title{Stress: multi-line install Sexpr expression}
\description{
Multi-line code, no braces in the body:
\Sexpr[results=text,stage=install]{
  paste("R",
        getRversion())
}.

Multi-line code WITH nested braces (if/else)

\Sexpr[results=text,stage=install]{
  if (nchar("abc") > 0) {
    "nonempty"
  } else {
    "empty"
  }
}.
}
\keyword{internal}
