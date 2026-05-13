r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
invisible(lapply(r_files, source))

fig_dir <- file.path("inst", "examples", "figures")
if (!dir.exists(fig_dir)) {
  dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
}

# Build a standardized CSV first to demonstrate the recommended workflow.
std_csv <- tempfile(pattern = "mmv_watermaze_standard_", fileext = ".csv")
on.exit(unlink(std_csv, force = TRUE), add = TRUE)
convert_mmviz_csv(
  path = file.path("inst", "templates", "watermaze_template.csv"),
  out_path = std_csv,
  task = "watermaze",
  overwrite = TRUE
)

# Water maze example figure.
plot_watermaze(
  std_csv,
  cfg = list(
    style_mode = "thisplot",
    plot_mode = "line_gradient",
    panel_per_row = 4,
    out_file = file.path(fig_dir, "watermaze_demo.png")
  )
)

# Minefield example figure.
plot_minefield(
  file.path("inst", "templates", "minefield_template.csv"),
  cfg = list(
    style_mode = "thisplot",
    overlay_trajectory = TRUE,
    panel_per_row = 2,
    out_file = file.path(fig_dir, "minefield_demo.png")
  )
)

cat("Generated README example figures:\n")
cat(normalizePath(file.path(fig_dir, "watermaze_demo.png")), "\n")
cat(normalizePath(file.path(fig_dir, "minefield_demo.png")), "\n")
