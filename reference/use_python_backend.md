# Enable or disable optional Python backend

This package is R-first. Python is optional and accessed via reticulate.

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
