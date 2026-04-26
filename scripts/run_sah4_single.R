# One-file quick run for legacy SAH CSV:
# convert first, then plot from standardized CSV.

r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
invisible(lapply(r_files, source))

csv_candidates <- list.files("..", pattern = "^sah--4.*\\.csv$", full.names = TRUE)
if (length(csv_candidates) == 0) {
  stop("Cannot find sah--4 source CSV in parent directory.")
}
input_csv <- csv_candidates[[1]]

if (!dir.exists("outputs")) {
  dir.create("outputs", recursive = TRUE)
}

std_csv <- "outputs/sah4_standard.csv"
convert_mmviz_csv(
  path = input_csv,
  out_path = std_csv,
  task = "watermaze",
  overwrite = TRUE
)

p <- plot_watermaze(
  std_csv,
  cfg = list(
    style_mode = "thisplot",
    plot_mode = "line_gradient",
    group_order = c("SAH"),
    panel_per_row = 1,
    title = "SAH Single-File Trajectory",
    out_file = "outputs/sah4_line_gradient.png",
    figure_width = 5.8,
    figure_height = 6.4
  )
)

print(p)
cat("Standardized CSV: ", normalizePath(std_csv), "\n", sep = "")
cat("Saved figure: ", normalizePath("outputs/sah4_line_gradient.png"), "\n", sep = "")
