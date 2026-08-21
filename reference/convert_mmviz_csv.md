# Convert one CSV into standardized mmviz schema

Convert one CSV into standardized mmviz schema

## Usage

``` r
convert_mmviz_csv(
  path,
  out_path = NULL,
  task = c("watermaze", "minefield"),
  overwrite = FALSE,
  include_optional = TRUE,
  keep_extra = FALSE,
  subject_id = NULL,
  group = NULL,
  trial_id = NULL
)
```

## Arguments

- path:

  Input CSV file path (legacy or standard).

- out_path:

  Output CSV file path. Defaults to `<input_stem>_standard.csv`.

- task:

  One of `watermaze` or `minefield`.

- overwrite:

  Whether to overwrite an existing output file.

- include_optional:

  Whether to include optional columns (`time_sec`, `event`) when
  present.

- keep_extra:

  Whether to keep extra non-schema columns in output.

- subject_id:

  Optional override for all rows.

- group:

  Optional override for all rows.

- trial_id:

  Optional override for all rows.

## Value

A one-row data frame with conversion metadata.

## Examples

``` r
source <- system.file("templates", "watermaze_template.csv", package = "MMV")
output <- tempfile(fileext = ".csv")
convert_mmviz_csv(source, output, overwrite = TRUE)
#>        task
#> 1 watermaze
#>                                                             input_file
#> 1 /home/runner/work/_temp/Library/MMV/templates/watermaze_template.csv
#>                            output_file source_format rows
#> 1 /tmp/RtmpHOwLvV/file1f7730d51d57.csv      standard   20
```
