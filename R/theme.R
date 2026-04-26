.mmviz_builtin_palette <- function() {
  list(
    text = "#1F2430",
    bg_watermaze = "#1E3277",
    bg_minefield = "#0F1B3D",
    guide = "#A7BFEF",
    line_halo = "#5ADFFF",
    line_gradient = c("#44EEFF", "#16CFFF", "#2BFFCB", "#FFF73A", "#FF9200", "#D90000"),
    heatmap_fill = c("navy", "blue", "cyan", "green", "yellow", "red"),
    mine_heatmap = c("#0A2A6E", "#0B5FA5", "#2DB7C4", "#7BDDAC", "#F7F797", "#E94B3C")
  )
}

.mmviz_thisplot_palette <- function() {
  runtime <- load_visual_runtime(
    style_pkg = "thisplot",
    function_map = list(
      thisplot = c("palette_colors", "scale_fill_this_d", "scale_color_this_d")
    ),
    attach_packages = FALSE
  )
  if (!"thisplot" %in% runtime$packages_loaded) {
    return(NULL)
  }

  palette_colors <- runtime$extracted_functions[["thisplot::palette_colors"]]
  if (is.null(palette_colors)) {
    return(NULL)
  }

  line_grad <- tryCatch(
    as.character(palette_colors(seq_len(6), palette = "RdYlBu", reverse = TRUE)),
    error = function(e) NULL
  )
  heat_fill <- tryCatch(
    as.character(palette_colors(seq_len(6), palette = "Spectral", reverse = TRUE)),
    error = function(e) NULL
  )
  mine_fill <- tryCatch(
    as.character(palette_colors(seq_len(6), palette = "YlOrRd", reverse = FALSE)),
    error = function(e) NULL
  )

  if (is.null(line_grad) || length(line_grad) < 3) line_grad <- c("#52D8FB", "#43C7E6", "#53D38C", "#E2D157", "#EE9A4E", "#D65A4A")
  if (is.null(heat_fill) || length(heat_fill) < 3) heat_fill <- c("#152A77", "#1F5FBF", "#32B8C9", "#7FD39D", "#EEDC79", "#E36D55")
  if (is.null(mine_fill) || length(mine_fill) < 3) mine_fill <- c("#0E2C7A", "#216CB2", "#40C0C4", "#88D9A3", "#F2DE8A", "#E36A55")

  list(
    text = "#2A2A2A",
    bg_watermaze = "#1B2D73",
    bg_minefield = "#12224A",
    guide = "#BFD1F5",
    line_halo = "#67D8FF",
    line_gradient = line_grad,
    heatmap_fill = heat_fill,
    mine_heatmap = mine_fill
  )
}

.mmviz_detect_thisplot_theme <- function() {
  candidates <- c("theme_this", "theme_thisplot", "theme_mengxu", "theme_pubr", "theme_clean")
  fn_map <- list()
  fn_map[["thisplot"]] <- candidates

  runtime <- load_visual_runtime(
    style_pkg = "thisplot",
    function_map = fn_map,
    attach_packages = FALSE
  )
  if (!"thisplot" %in% runtime$packages_loaded) {
    return(NULL)
  }

  for (nm in candidates) {
    key <- paste0("thisplot::", nm)
    fn <- runtime$extracted_functions[[key]]
    if (is.null(fn)) next
    th <- tryCatch(fn(), error = function(e) NULL)
    if (inherits(th, "theme")) {
      return(th)
    }
  }
  NULL
}

#' Return plotting theme and palette for mazeMineViz
#'
#' @param mode Theme mode, `thisplot` or `builtin`.
#'
#' @return A list with `mode`, `palette`, and `gg_theme`.
#' @export
theme_mmviz <- function(mode = c("thisplot", "builtin")) {
  mode <- tolower(as.character(mode)[1])
  if (!mode %in% c("thisplot", "builtin")) {
    stop("`mode` must be one of: thisplot, builtin.", call. = FALSE)
  }

  resolved_mode <- mode
  thisplot_theme <- NULL
  if (mode == "thisplot") {
    thisplot_theme <- .mmviz_detect_thisplot_theme()
    if (is.null(thisplot_theme)) {
      resolved_mode <- "builtin"
    }
  }

  palette <- if (resolved_mode == "thisplot") .mmviz_thisplot_palette() else .mmviz_builtin_palette()
  if (is.null(palette)) {
    resolved_mode <- "builtin"
    palette <- .mmviz_builtin_palette()
  }
  base_theme <- if (resolved_mode == "thisplot" && !is.null(thisplot_theme)) {
    thisplot_theme
  } else {
    ggplot2::theme_minimal(base_size = 12)
  }

  gg_theme <- base_theme +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      axis.title = ggplot2::element_blank(),
      axis.text = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(face = "bold", color = palette$text),
      legend.title = ggplot2::element_text(face = "bold"),
      legend.background = ggplot2::element_rect(fill = "white", color = NA)
    )

  list(
    mode = resolved_mode,
    palette = palette,
    gg_theme = gg_theme
  )
}
