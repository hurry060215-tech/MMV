#' MMV: water-maze and minefield trajectory visualization
#'
#' MMV reads a shared trajectory schema, converts supported legacy coordinate
#' streams, and creates water-maze or minefield plots in R. Start with
#' [read_mmviz_csv()], [plot_watermaze()], or [plot_minefield()]. Use
#' [plot_batch()] for manifest-driven rendering.
#'
#' Standard CSV files require the columns `subject_id`, `group`, `trial_id`,
#' `frame`, `x`, and `y`. The optional columns are `time_sec` and `event`.
#'
#' @keywords internal
"_PACKAGE"
