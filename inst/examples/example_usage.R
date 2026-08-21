# Minimal runnable example for an installed copy of MMV.
library(MMV)

output_dir <- file.path(tempdir(), "MMV-example")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
water_csv <- system.file("templates", "watermaze_template.csv", package = "MMV")
mine_csv <- system.file("templates", "minefield_template.csv", package = "MMV")

# 1) Convert (legacy/standard) CSV into unified schema.
cnv <- convert_mmviz_csv(
  path = water_csv,
  out_path = file.path(output_dir, "watermaze_template_standard.csv"),
  task = "watermaze",
  overwrite = TRUE
)
print(cnv)

# 2) Water maze line-gradient trajectory.
invisible(plot_watermaze(
  cnv$output_file,
  cfg = list(
    style_mode = "builtin",
    plot_mode = "line_gradient",
    out_file = file.path(output_dir, "watermaze_demo.png")
  )
))

# 3) Minefield heatmap + trajectory overlay.
invisible(plot_minefield(
  mine_csv,
  cfg = list(
    style_mode = "builtin",
    overlay_trajectory = TRUE,
    out_file = file.path(output_dir, "minefield_demo.png")
  )
))

cat("Example outputs: ", normalizePath(output_dir), "\n", sep = "")
