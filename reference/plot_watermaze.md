# Plot water maze trajectories

Plot water maze trajectories

## Usage

``` r
plot_watermaze(input, cfg = list())
```

## Arguments

- input:

  CSV file path or standardized data frame.

- cfg:

  Named configuration list. Common options are `style_mode`, `plot_mode`
  (`"line_gradient"` or `"heatmap"`), `group_order`, `panel_per_row`,
  `pool_center`, `pool_radius`, and `out_file`.

## Value

A ggplot object.

## Examples

``` r
path <- system.file("templates", "watermaze_template.csv", package = "MMV")
plot_watermaze(path, cfg = list(style_mode = "builtin"))
```
