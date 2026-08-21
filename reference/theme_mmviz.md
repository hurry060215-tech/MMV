# Return the plotting theme and palette used by MMV

Return the plotting theme and palette used by MMV

## Usage

``` r
theme_mmviz(mode = c("thisplot", "builtin"))
```

## Arguments

- mode:

  Theme mode, `thisplot` or `builtin`.

## Value

A list with `mode`, `palette`, and `gg_theme`.

## Examples

``` r
theme <- theme_mmviz("builtin")
names(theme)
#> [1] "mode"     "palette"  "gg_theme"
```
