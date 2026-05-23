# Load full visualization runtime and extract package functions

This helper explicitly loads runtime namespaces and can extract selected
functions from target packages while keeping original function
environments.

## Usage

``` r
load_visual_runtime(
  style_pkg = "thisplot",
  extra_pkgs = NULL,
  function_map = list(),
  attach_packages = FALSE
)
```

## Arguments

- style_pkg:

  Primary style package, default `thisplot`.

- extra_pkgs:

  Optional character vector of extra package names.

- function_map:

  Named list: package -\> character vector of function names.

- attach_packages:

  Whether to attach packages to search path.

## Value

A list with loaded packages, extracted functions, and a runtime env.
