% Stress fixture: multiple install \Sexpr, including at section start, at end,
% and two adjacent with no static text between. 
\name{stress_multi}
\alias{stress_multi}
\title{Stress: multiple / adjacent install Sexpr}
\description{
\Sexpr[results=text,stage=install]{ "START" } opens the section (empty leading anchor).

Two adjacent with nothing between them: \Sexpr[results=text,stage=install]{ "AAA" }\Sexpr[results=text,stage=install]{ "BBB" } and done.

Two adjacent with text that repeats between them: \Sexpr[results=text,stage=install]{ "AAA" }AAA\Sexpr[results=text,stage=install]{ "BBB" } and done.

A final one right at the end: \Sexpr[results=text,stage=install]{ "END" }
}
\keyword{internal}
