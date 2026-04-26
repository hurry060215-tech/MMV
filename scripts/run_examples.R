r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
invisible(lapply(r_files, source))

if (!dir.exists("outputs")) {
  dir.create("outputs", recursive = TRUE)
}

# 1) Convert template CSV (works for standard or legacy input)
convert_mmviz_csv(
  path = "inst/templates/watermaze_template.csv",
  out_path = "outputs/watermaze_template_standard.csv",
  task = "watermaze",
  overwrite = TRUE
)

# 2) Water maze
plot_watermaze(
  "outputs/watermaze_template_standard.csv",
  cfg = list(
    style_mode = "thisplot",
    plot_mode = "line_gradient",
    out_file = "outputs/watermaze_line_gradient.png"
  )
)

# 3) Minefield
plot_minefield(
  "inst/templates/minefield_template.csv",
  cfg = list(
    style_mode = "thisplot",
    overlay_trajectory = TRUE,
    out_file = "outputs/minefield_overlay.png"
  )
)

# 4) Batch
res <- plot_batch(
  manifest = "inst/templates/manifest_template.csv",
  out_dir = "outputs",
  cfg = list(style_mode = "thisplot")
)
print(res)
