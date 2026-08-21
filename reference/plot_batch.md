# Batch plotting from manifest

Batch plotting from manifest

## Usage

``` r
plot_batch(manifest, out_dir, cfg = list())
```

## Arguments

- manifest:

  Data frame or path to a CSV/YAML manifest. Relative input paths in a
  file manifest are resolved from the manifest's directory.

- out_dir:

  Output directory.

- cfg:

  Base config list.

## Value

A data frame with one `ok` or `error` status per job. A failed job does
not stop later jobs.

## Examples

``` r
manifest <- system.file("templates", "manifest_template.csv", package = "MMV")
result <- plot_batch(manifest, file.path(tempdir(), "MMV-batch"))
result[, c("task", "status")]
#>        task status
#> 1 watermaze     ok
#> 2 minefield     ok
```
