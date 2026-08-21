# Plot an MMV task through one unified entry point

This convenience wrapper delegates to
[`plot_watermaze()`](https://hurry060215-tech.github.io/MMV/reference/plot_watermaze.md)
or
[`plot_minefield()`](https://hurry060215-tech.github.io/MMV/reference/plot_minefield.md)
and returns the same ggplot object.

## Usage

``` r
plot_mmviz(input, task, cfg = list(), out_file = NULL)
```

## Arguments

- input:

  CSV file path or standardized data frame.

- task:

  Either `"watermaze"` or `"minefield"`.

- cfg:

  Configuration list accepted by the task-specific plotter.

- out_file:

  Optional output path. When supplied, it overrides `cfg$out_file`.

## Value

A ggplot object.

## Examples

``` r
path <- system.file("templates", "watermaze_template.csv", package = "MMV")
plot_mmviz(path, task = "watermaze", cfg = list(style_mode = "builtin"))
```
