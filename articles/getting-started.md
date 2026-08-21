# Getting started with MMV

MMV can create a complete starter folder in one command:

``` r

library(MMV)
project <- mmviz_init("my-mmv-project")
project
```

The folder contains editable water-maze and minefield CSV files, a
manifest, an `outputs/` directory, and a standalone runner. Run it from
any directory:

``` bash
Rscript my-mmv-project/run_mmviz.R
```

For a single file, use the unified plotting entry point:

``` r

plot_mmviz(
  "my-mmv-project/data/watermaze.csv",
  task = "watermaze",
  out_file = "my-mmv-project/outputs/watermaze.png",
  cfg = list(style_mode = "builtin")
)
```

The task-specific functions remain available when you need their full
intent to be explicit:

``` r

plot_watermaze("watermaze.csv", cfg = list(style_mode = "builtin"))
plot_minefield("minefield.csv", cfg = list(style_mode = "builtin"))
```

Standard CSV files require `subject_id`, `group`, `trial_id`, `frame`,
`x`, and `y`. Optional columns are `time_sec` and `event`. Batch
manifests need `task` and `input`; relative inputs are resolved from the
manifest directory.

Each batch result includes `status` and `message`. A malformed row is
reported with its manifest row number while later independent rows
continue. Output filenames must be unique within a batch.

On Windows, Unicode filenames require an UTF-8-capable R locale. If a
shell has exported the POSIX value `C.UTF-8`, clear `LANG`, `LC_ALL`,
and `LC_CTYPE` for the current PowerShell process before starting R. MMV
does not change global locale settings automatically.
