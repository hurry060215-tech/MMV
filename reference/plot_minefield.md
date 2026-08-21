# Plot minefield heatmap

Plot minefield heatmap

## Usage

``` r
plot_minefield(input, cfg = list())
```

## Arguments

- input:

  CSV file path or standardized data frame.

- cfg:

  Named configuration list. Common options are `style_mode`, `plot_mode`
  (`"heatmap_only"` or `"heatmap_with_trajectory"`),
  `overlay_trajectory`, `group_order`, `panel_per_row`, and `out_file`.

## Value

A ggplot object.

## Examples

``` r
path <- system.file("templates", "minefield_template.csv", package = "MMV")
plot_minefield(path, cfg = list(style_mode = "builtin"))
```
