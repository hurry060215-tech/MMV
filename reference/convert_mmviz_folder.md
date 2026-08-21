# Convert all CSVs in a folder into standardized mmviz schema

Convert all CSVs in a folder into standardized mmviz schema

## Usage

``` r
convert_mmviz_folder(
  input_dir,
  out_dir = file.path(input_dir, "converted_standard"),
  task = c("watermaze", "minefield"),
  pattern = "\\.csv$",
  recursive = FALSE,
  overwrite = FALSE,
  include_optional = TRUE,
  keep_extra = FALSE
)
```

## Arguments

- input_dir:

  Directory containing source CSV files.

- out_dir:

  Output directory for standardized CSV files.

- task:

  One of `watermaze` or `minefield`.

- pattern:

  File-matching regex for CSV discovery.

- recursive:

  Whether to search `input_dir` recursively. Subdirectory structure is
  preserved under `out_dir` to prevent filename collisions.

- overwrite:

  Whether to overwrite existing converted files.

- include_optional:

  Whether to include optional columns (`time_sec`, `event`) when
  present.

- keep_extra:

  Whether to keep extra non-schema columns in output.

## Value

A data frame summarizing conversion status for each file.

## Examples

``` r
if (FALSE) { # \dontrun{
convert_mmviz_folder("raw_tracks", "standard_tracks", recursive = TRUE)
} # }
```
