# Initialize a ready-to-run MMV project

Creates a small project containing editable water-maze and minefield CSV
files, a batch manifest, an output directory, and a standalone
`run_mmviz.R` script. Existing unrelated files are never removed.

## Usage

``` r
mmviz_init(path = "MMV-project", overwrite = FALSE, quiet = FALSE)
```

## Arguments

- path:

  Directory to create.

- overwrite:

  Whether to replace MMV-managed starter files that already exist. The
  default is `FALSE`.

- quiet:

  Whether to suppress the success message.

## Value

A one-row data frame containing normalized project paths.

## Examples

``` r
project <- mmviz_init(tempfile("MMV-project-"), quiet = TRUE)
file.exists(project$run_script)
#> [1] TRUE
```
