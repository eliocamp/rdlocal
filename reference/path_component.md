# Extract component of a path

Extract component of a path

## Usage

``` r
path_component(path, depth = 0)
```

## Arguments

- path:

  a vector of paths

- depth:

  positive integer indicating the component to extract. 0 means the last
  component, 1 means its parent and so on.

## Details

This was used in a previous implementation of the package and left here
just in case. Probably can delete, but since it's not exported and is a
simple function, it doesn't hurt.

## Examples

``` r
if (FALSE) { # \dontrun{
path_component("/home/user/Documents/file.txt")
path_component("/home/user/Documents/file.txt", depth = 2)
} # }
```
