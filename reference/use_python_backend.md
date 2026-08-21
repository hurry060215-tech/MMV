# Enable or disable optional Python backend

This package is R-first. Python is optional and accessed via reticulate.
The backend hook is experimental: an external module must provide
`postprocess_track(data, task)` or `postprocess(data, task)`. See the
online documentation and the linked backend-contract issue before
production use.

## Usage

``` r
use_python_backend(enable = FALSE, module = NULL)
```

## Arguments

- enable:

  Logical, whether to enable python hooks.

- module:

  Optional Python module name. If NULL, uses `mmviz_backend`.

## Value

(invisibly) backend state list.

## Examples

``` r
if (FALSE) { # \dontrun{
use_python_backend(TRUE, module = "mmviz_backend")
} # }
```
