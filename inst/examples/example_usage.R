# Minimal runnable examples for MMV (development mode)

r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
invisible(lapply(r_files, source))

if (!dir.exists("outputs")) {
  dir.create("outputs", recursive = TRUE, showWarnings = FALSE)
}

# 1) Convert (legacy/standard) CSV into unified schema.
cnv <- convert_mmviz_csv(
  path = "inst/templates/watermaze_template.csv",
  out_path = "outputs/watermaze_template_standard.csv",
  task = "watermaze",
  overwrite = TRUE
)
print(cnv)

# 2) Water maze line-gradient trajectory.
plot_watermaze(
  "outputs/watermaze_template_standard.csv",
  cfg = list(
    style_mode = "thisplot",
    plot_mode = "line_gradient",
    out_file = "outputs/watermaze_demo.png"
  )
)

# 3) Minefield heatmap + trajectory overlay.
plot_minefield(
  "inst/templates/minefield_template.csv",
  cfg = list(
    style_mode = "thisplot",
    overlay_trajectory = TRUE,
    out_file = "outputs/minefield_demo.png"
  )
)

cat("Saved: ", normalizePath("outputs/watermaze_demo.png"), "\n", sep = "")
cat("Saved: ", normalizePath("outputs/minefield_demo.png"), "\n", sep = "")
