# Write and read a flattened rd file

Write and read a flattened rd file

## Usage

``` r
rd_flat_write(rd_flat, file)
```

## Arguments

- rd_flat:

  an rd_flattened file returned by `[rd_flatten]`.

- file:

  path to the file.

## Details

`rd_flat_write` writes the result of `[rd_flatten]` into a yaml file
that then can be used for translation. `rd_flat_read` reads this file
and the result can be used as translation for `[rd_translate]`.
