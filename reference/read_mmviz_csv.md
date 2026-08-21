# Read standard CSV for watermaze or minefield tasks

Read standard CSV for watermaze or minefield tasks

## Usage

``` r
read_mmviz_csv(path, task = c("watermaze", "minefield"))
```

## Arguments

- path:

  CSV file path.

- task:

  One of `watermaze` or `minefield`.

## Value

A tibble with standard columns.

## Examples

``` r
path <- system.file("templates", "watermaze_template.csv", package = "MMV")
data <- read_mmviz_csv(path, task = "watermaze")
head(data)
#> # A tibble: 6 × 8
#>   subject_id group trial_id frame     x     y time_sec event  
#>   <chr>      <chr> <chr>    <int> <int> <int>    <dbl> <chr>  
#> 1 rat01      Sham  t1           1   210   120     0    "start"
#> 2 rat01      Sham  t1           2   214   124     0.05 ""     
#> 3 rat01      Sham  t1           3   220   130     0.1  ""     
#> 4 rat01      Sham  t1           4   225   138     0.15 ""     
#> 5 rat01      Sham  t1           5   228   147     0.2  ""     
#> 6 rat01      Sham  t1           6   226   157     0.25 ""     
```
