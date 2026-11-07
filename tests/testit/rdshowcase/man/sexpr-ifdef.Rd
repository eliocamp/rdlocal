% Sexpr inside ifdef
\name{sexprifdef}
\title{Sexpr inside an ifdef}
\description{
Text immediately below will display the operating system:
#ifdef windows
Sexpr[stage=build]{"windows at build"}
Sexpr[stage=install]{"windows at install"}
Sexpr[stage=render]{"windows at render"}
#endif
#ifdef unix
Sexpr[stage=build]{"unix at build"}
Sexpr[stage=install]{"unix at install"}
Sexpr[stage=render]{"unix at render"}
#endif
And this text will always appear.
}
\keyword{internal}
