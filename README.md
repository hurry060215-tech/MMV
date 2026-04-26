# MMV

R-first toolkit for automatic visualization of **water maze** and **minefield** trajectory tasks.

`MMV` is designed for:
- standard CSV input
- explicit conversion from legacy trajectory CSV
- two main user-facing plotting functions
- default `thisplot` style with builtin fallback
- optional Python extension from R via `reticulate`

## Quick Start

### 1) Install dependencies
```r
install.packages(c("ggplot2", "dplyr", "cowplot", "testthat"))
install.packages(c("reticulate", "yaml"))  # optional
```

Install `thisplot` from its repository if you want `style_mode = "thisplot"`:
- [thisplot](https://github.com/mengxu98/thisplot)

### 2) Install MMV from GitHub
```r
install.packages("remotes")
remotes::install_github("YOUR_GITHUB_USERNAME/MMV")
library(MMV)
```

PowerShell publish helper (for repository owner `hurry060215-tech`):
```powershell
powershell -ExecutionPolicy Bypass -File scripts/publish_mmv_github.ps1
```

### 3) Source package files in development mode
```r
r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
invisible(lapply(r_files, source))
```

### 4) Convert a legacy CSV (recommended first step)
```r
src <- list.files("..", pattern = "^sah--4.*\\.csv$", full.names = TRUE)[1]
cnv <- convert_mmviz_csv(
  path = src,
  task = "watermaze",
  out_path = "outputs/sah4_standard.csv",
  overwrite = TRUE
)
print(cnv)
```

### 5) Plot water maze from CSV
```r
p <- plot_watermaze(
  "outputs/sah4_standard.csv",
  cfg = list(
    style_mode = "thisplot",
    plot_mode = "line_gradient",
    out_file = "outputs/watermaze_demo.png"
  )
)
```

### 6) Plot minefield from CSV
```r
p <- plot_minefield(
  "inst/templates/minefield_template.csv",
  cfg = list(
    style_mode = "thisplot",
    overlay_trajectory = TRUE,
    out_file = "outputs/minefield_demo.png"
  )
)
```

### 7) Batch plotting
```r
res <- plot_batch(
  manifest = "inst/templates/manifest_template.csv",
  out_dir = "outputs",
  cfg = list(style_mode = "thisplot")
)
print(res)
```

## Input Schema (CSV)

Required columns:
- `subject_id`
- `group`
- `trial_id`
- `frame`
- `x`
- `y`

Optional columns:
- `time_sec`
- `event`

The reader also supports legacy coordinate-stream CSV format (for example: `"233,135","233,135",...`).

Batch conversion helper:
```r
cnv_res <- convert_mmviz_folder(
  input_dir = "..",
  out_dir = "outputs/converted_standard",
  task = "watermaze",
  pattern = "\\.csv$",
  overwrite = TRUE
)
print(cnv_res)
```

## Main Functions

- `plot_watermaze(input, cfg = list())`
- `plot_minefield(input, cfg = list())`
- `convert_mmviz_csv(path, out_path = NULL, task = "watermaze", overwrite = FALSE)`
- `convert_mmviz_folder(input_dir, out_dir, task = "watermaze", ...)`

`input` can be:
- a CSV path (recommended)
- or a data.frame with the standard columns

## Style Modes

- `style_mode = "thisplot"`: use `thisplot::theme_this()` and `thisplot::palette_colors()` when available.
- `style_mode = "builtin"`: use internal fallback palette/theme.

Default is `thisplot` with automatic fallback.

## Optional Python Backend

R is the primary runtime. If you want to add Python-based post-processing:
```r
use_python_backend(enable = TRUE, module = "your_module_name")
```

Then `plot_*` functions can call Python hooks through `reticulate`.

## Runtime Loader for Function Extraction

If you want a full runtime load plus selective function extraction:
```r
rt <- load_visual_runtime(
  style_pkg = "thisplot",
  extra_pkgs = c("stats"),
  function_map = list(
    thisplot = c("theme_this", "palette_colors"),
    stats = c("median")
  )
)
```

## pkgdown Setup (GitHub Pages)

`pkgdown` is not automatic by GitHub itself.  
This repo includes:
- `_pkgdown.yml`
- `.github/workflows/pkgdown.yaml`

Before first deployment:
1. Replace `YOUR_GITHUB_USERNAME` in `_pkgdown.yml`.
2. Push to `main`.
3. In GitHub repository settings, enable GitHub Pages from `gh-pages` branch.
