`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0) {
    return(y)
  }
  x
}

mmviz_normalize_task <- function(task) {
  if (length(task) != 1L || is.na(task)) {
    stop("`task` must be one of: watermaze, minefield.", call. = FALSE)
  }
  task <- tolower(trimws(as.character(task)[1]))
  if (!nzchar(task) || !task %in% c("watermaze", "minefield")) {
    stop("`task` must be one of: watermaze, minefield.", call. = FALSE)
  }
  task
}

mmviz_required_columns <- function() {
  c("subject_id", "group", "trial_id", "frame", "x", "y")
}

mmviz_optional_columns <- function() {
  c("time_sec", "event")
}

mmviz_assert_scalar_path <- function(path, arg = "path") {
  if (
    !is.character(path) || length(path) != 1L || is.na(path) ||
      !nzchar(trimws(path))
  ) {
    stop(sprintf("`%s` must be one non-empty file path.", arg), call. = FALSE)
  }
  path
}

mmviz_is_absolute_path <- function(path) {
  grepl("^([A-Za-z]:[\\\\/]|/|\\\\\\\\)", path)
}

mmviz_assert_required_values <- function(data, object_name = "data") {
  for (col in c("subject_id", "group", "trial_id")) {
    value <- as.character(data[[col]])
    if (any(is.na(value) | !nzchar(trimws(value)))) {
      stop(
        sprintf("%s column `%s` has missing or empty values.", object_name, col),
        call. = FALSE
      )
    }
    data[[col]] <- value
  }

  for (col in c("frame", "x", "y")) {
    value <- data[[col]]
    if (any(is.na(value) | !is.finite(value))) {
      stop(
        sprintf("%s column `%s` must contain only finite values.", object_name, col),
        call. = FALSE
      )
    }
  }
  data
}

mmviz_default_cfg <- function(task = c("watermaze", "minefield")) {
  task <- mmviz_normalize_task(task[1])

  common <- list(
    style_mode = "thisplot",
    group_order = NULL,
    panel_per_row = 4L,
    figure_width = NULL,
    figure_height = NULL,
    dpi = 300,
    output_format = "png",
    out_file = NULL
  )

  if (task == "watermaze") {
    return(c(common, list(
      plot_mode = "line_gradient",
      background_color = "#1E3277",
      guide_color = "#A7BFEF",
      track_linewidth = 0.85,
      pool_center = NULL,
      pool_radius = NULL,
      overlay_trajectory = TRUE
    )))
  }

  c(common, list(
    plot_mode = "heatmap_only",
    background_color = "#0F1B3D",
    guide_color = "#C7D4F4",
    track_linewidth = 0.7,
    overlay_trajectory = FALSE,
    field_xlim = NULL,
    field_ylim = NULL
  ))
}

mmviz_merge_cfg <- function(default_cfg, cfg = list()) {
  if (is.null(cfg)) {
    return(default_cfg)
  }
  if (!is.list(cfg)) {
    stop("`cfg` must be a list.", call. = FALSE)
  }
  out <- default_cfg
  for (nm in names(cfg)) {
    out[[nm]] <- cfg[[nm]]
  }
  out
}

mmviz_validate_cfg <- function(task, cfg) {
  task <- mmviz_normalize_task(task)

  style_mode <- tolower(as.character(cfg$style_mode)[1])
  if (is.na(style_mode) || !style_mode %in% c("thisplot", "builtin")) {
    stop("`cfg$style_mode` must be `thisplot` or `builtin`.", call. = FALSE)
  }

  mode <- tolower(as.character(cfg$plot_mode)[1])
  valid_modes <- if (task == "watermaze") {
    c("line_gradient", "heatmap")
  } else {
    c("heatmap_only", "heatmap_with_trajectory")
  }
  if (is.na(mode) || !mode %in% valid_modes) {
    stop(
      sprintf(
        "`cfg$plot_mode` for %s must be one of: %s.",
        task,
        paste(valid_modes, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  positive <- c("panel_per_row", "dpi", "track_linewidth")
  optional_positive <- c("figure_width", "figure_height")
  for (nm in c(positive, optional_positive)) {
    value <- cfg[[nm]] %||% NULL
    if (is.null(value) && nm %in% optional_positive) {
      next
    }
    number <- suppressWarnings(as.numeric(value))
    if (
      length(number) != 1L || is.na(number) || !is.finite(number) ||
        number <= 0
    ) {
      stop(sprintf("`cfg$%s` must be one positive number.", nm), call. = FALSE)
    }
  }

  if (as.numeric(cfg$panel_per_row) %% 1 != 0) {
    stop("`cfg$panel_per_row` must be a whole number.", call. = FALSE)
  }
  if (!is.null(cfg$out_file)) {
    mmviz_assert_scalar_path(cfg$out_file, "cfg$out_file")
  }
  if (!is.null(cfg$title) && (
    !is.character(cfg$title) || length(cfg$title) != 1L || is.na(cfg$title)
  )) {
    stop("`cfg$title` must be one character value.", call. = FALSE)
  }
  cfg
}

mmviz_assert_density_data <- function(data, label = "data") {
  if (
    nrow(data) < 2L || length(unique(data$x)) < 2L ||
      length(unique(data$y)) < 2L
  ) {
    stop(
      sprintf(
        "%s needs at least two distinct x and y coordinates for a heatmap.",
        label
      ),
      call. = FALSE
    )
  }
  invisible(data)
}

mmviz_label <- function(key) {
  labels <- list(
    watermaze_title = "Water Maze Trajectory",
    minefield_title = "Minefield Heatmap",
    legend_max = "MAX",
    legend_density = "Heat",
    legend_time = "Time"
  )
  labels[[key]] %||% key
}

mmviz_assert_columns <- function(df, required_cols, object_name = "data") {
  missing_cols <- setdiff(required_cols, names(df))
  if (length(missing_cols) > 0) {
    stop(
      sprintf(
        "%s is missing required columns: %s",
        object_name,
        paste(missing_cols, collapse = ", ")
      ),
      call. = FALSE
    )
  }
}

mmviz_to_numeric_columns <- function(df, cols, object_name = "data") {
  for (col in cols) {
    original <- df[[col]]
    if (!is.numeric(original)) {
      converted <- suppressWarnings(as.numeric(original))
      bad <- is.na(converted) & !is.na(original) & trimws(as.character(original)) != ""
      if (any(bad)) {
        stop(
          sprintf("%s column `%s` contains non-numeric values.", object_name, col),
          call. = FALSE
        )
      }
      df[[col]] <- converted
    }
  }
  df
}

mmviz_reorder_groups <- function(groups, preferred_order = NULL) {
  groups <- unique(as.character(groups))
  if (is.null(preferred_order) || length(preferred_order) == 0) {
    return(groups)
  }
  preferred_order <- unique(as.character(preferred_order))
  c(intersect(preferred_order, groups), setdiff(groups, preferred_order))
}

mmviz_make_pool_guides <- function(cx, cy, radius) {
  theta <- seq(0, 2 * pi, length.out = 361)
  mk_ring <- function(frac) {
    data.frame(
      x = cx + radius * frac * cos(theta),
      y = cy + radius * frac * sin(theta)
    )
  }
  list(
    outer = mk_ring(1.0),
    mid = mk_ring(0.66),
    inner = mk_ring(0.33),
    cross = data.frame(
      x = c(cx - radius, cx),
      y = c(cy, cy - radius),
      xend = c(cx + radius, cx),
      yend = c(cy, cy + radius)
    )
  )
}

mmviz_safe_file_stem <- function(path) {
  stem <- tools::file_path_sans_ext(basename(path))
  stem <- gsub("[^\\p{L}\\p{N}_-]+", "_", enc2utf8(stem), perl = TRUE)
  stem <- gsub("^_+|_+$", "", stem)
  if (!nzchar(stem)) "plot" else stem
}

mmviz_save_plot <- function(plot_obj, cfg) {
  out_file <- cfg$out_file %||% NULL
  if (is.null(out_file)) {
    return(invisible(NULL))
  }

  out_dir <- dirname(out_file)
  if (!dir.exists(out_dir)) {
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  }

  width <- as.numeric(cfg$figure_width %||% 10)
  height <- as.numeric(cfg$figure_height %||% 6)
  dpi <- as.integer(cfg$dpi %||% 300)
  ggplot2::ggsave(
    filename = out_file,
    plot = plot_obj,
    width = width,
    height = height,
    dpi = dpi,
    bg = "white"
  )
  invisible(normalizePath(out_file, winslash = "/", mustWork = FALSE))
}

mmviz_parse_scalar <- function(x) {
  if (length(x) == 0 || is.null(x) || is.na(x[1])) {
    return(NULL)
  }
  if (is.logical(x) || is.numeric(x)) {
    return(x[1])
  }
  x <- trimws(as.character(x)[1])
  if (!nzchar(x)) {
    return(NULL)
  }
  low <- tolower(x)
  if (low %in% c("true", "t", "yes", "y", "1")) return(TRUE)
  if (low %in% c("false", "f", "no", "n", "0")) return(FALSE)
  num <- suppressWarnings(as.numeric(x))
  if (!is.na(num)) return(num)
  x
}
