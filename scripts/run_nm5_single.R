# One-file quick run for your current legacy coordinate CSV:
# ../nm--5轨迹坐标点.csv

if (!requireNamespace("pkgload", quietly = TRUE)) {
  stop("Install development dependency `pkgload` before running this script.")
}
pkgload::load_all(".", quiet = TRUE, compile = FALSE)

input_csv <- file.path("..", "nm--5轨迹坐标点.csv")
if (!file.exists(input_csv)) {
  stop(sprintf("Input file not found: %s", normalizePath(input_csv, mustWork = FALSE)))
}

if (!dir.exists("outputs")) {
  dir.create("outputs", recursive = TRUE)
}

p <- plot_watermaze(
  input_csv,
  cfg = list(
    # style_mode = "thisplot",
    plot_mode = "line_gradient",
    group_order = c("NM"),
    panel_per_row = 1,
    title = "NM Single-File Trajectory",
    out_file = "outputs/nm5_line_gradient.png",
    figure_width = 5.8,
    figure_height = 6.4
  )
)

print(p)
cat("Saved: ", normalizePath("outputs/nm5_line_gradient.png"), "\n", sep = "")
