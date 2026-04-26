.mmviz_estimate_pool_geometry <- function(data, cfg) {
  center <- cfg$pool_center %||% NULL
  radius <- cfg$pool_radius %||% NULL

  if (!is.null(center) && length(center) == 2 && all(is.finite(as.numeric(center)))) {
    cx <- as.numeric(center[1])
    cy <- as.numeric(center[2])
  } else {
    x_q <- stats::quantile(data$x, probs = c(0.005, 0.995), na.rm = TRUE)
    y_q <- stats::quantile(data$y, probs = c(0.005, 0.995), na.rm = TRUE)
    cx <- mean(x_q)
    cy <- mean(y_q)
  }

  if (!is.null(radius) && is.finite(as.numeric(radius)) && as.numeric(radius) > 0) {
    r <- as.numeric(radius)
  } else {
    x_q <- stats::quantile(data$x, probs = c(0.005, 0.995), na.rm = TRUE)
    y_q <- stats::quantile(data$y, probs = c(0.005, 0.995), na.rm = TRUE)
    r <- 0.52 * max(diff(x_q), diff(y_q))
  }

  list(cx = cx, cy = cy, radius = r)
}

.mmviz_build_watermaze_group_plot <- function(df_group, group_label, geo, cfg, style) {
  bg_col <- cfg$background_color %||% style$palette$bg_watermaze
  guide_col <- cfg$guide_color %||% style$palette$guide
  track_w <- as.numeric(cfg$track_linewidth %||% 0.85)
  mode <- tolower(as.character(cfg$plot_mode %||% "line_gradient"))
  labels <- list(legend_max = mmviz_label("legend_max"))
  guides <- mmviz_make_pool_guides(geo$cx, geo$cy, geo$radius)

  track_df <- df_group %>%
    dplyr::arrange(.data$subject_id, .data$trial_id, .data$frame) %>%
    dplyr::group_by(.data$subject_id, .data$trial_id) %>%
    dplyr::mutate(
      .path_group = paste0(.data$subject_id, "::", .data$trial_id),
      .frame01 = (dplyr::row_number() - 1) / pmax(dplyr::n() - 1, 1)
    ) %>%
    dplyr::ungroup()

  base_plot <- ggplot2::ggplot() +
    ggplot2::annotate("rect", xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = Inf, fill = bg_col) +
    ggplot2::geom_path(
      data = guides$outer,
      ggplot2::aes(.data$x, .data$y),
      color = guide_col,
      linewidth = 0.8
    ) +
    ggplot2::geom_path(
      data = guides$mid,
      ggplot2::aes(.data$x, .data$y),
      color = guide_col,
      linewidth = 0.55
    ) +
    ggplot2::geom_path(
      data = guides$inner,
      ggplot2::aes(.data$x, .data$y),
      color = guide_col,
      linewidth = 0.55
    ) +
    ggplot2::geom_segment(
      data = guides$cross,
      ggplot2::aes(.data$x, .data$y, xend = .data$xend, yend = .data$yend),
      color = guide_col,
      linewidth = 0.55
    ) +
    ggplot2::coord_fixed(
      xlim = c(geo$cx - geo$radius, geo$cx + geo$radius),
      ylim = c(geo$cy + geo$radius, geo$cy - geo$radius),
      expand = FALSE,
      clip = "on"
    ) +
    ggplot2::labs(title = group_label) +
    style$gg_theme +
    ggplot2::theme(
      panel.background = ggplot2::element_rect(fill = bg_col, color = NA),
      plot.background = ggplot2::element_rect(fill = "white", color = NA),
      plot.title = ggplot2::element_text(size = 13, hjust = 0.5, face = "bold"),
      legend.position = "right",
      legend.title = ggplot2::element_text(size = 10, color = "#8E7D4C", hjust = 0.5),
      legend.text = ggplot2::element_text(size = 10, color = "#8E7D4C"),
      plot.margin = ggplot2::margin(4, 4, 4, 4)
    )

  if (mode == "line_gradient") {
    p <- base_plot +
      ggplot2::geom_path(
        data = track_df,
        ggplot2::aes(.data$x, .data$y, group = .data$.path_group),
        color = style$palette$line_halo,
        linewidth = track_w * 1.65,
        alpha = 0.35,
        lineend = "round"
      ) +
      ggplot2::geom_path(
        data = track_df,
        ggplot2::aes(.data$x, .data$y, group = .data$.path_group, color = .data$.frame01),
        linewidth = track_w,
        alpha = 0.98,
        lineend = "round"
      ) +
      ggplot2::scale_color_gradientn(
        colors = style$palette$line_gradient,
        limits = c(0, 1),
        breaks = c(0),
        labels = c("0"),
        name = labels$legend_max,
        guide = ggplot2::guide_colorbar(
          title.position = "top",
          title.hjust = 0.5,
          ticks = FALSE,
          barheight = grid::unit(34, "mm"),
          barwidth = grid::unit(3.8, "mm")
        )
      )
    return(p)
  }

  p <- base_plot +
    ggplot2::stat_density_2d(
      data = track_df,
      ggplot2::aes(.data$x, .data$y, fill = ggplot2::after_stat(.data$ndensity)),
      geom = "raster",
      contour = FALSE,
      n = 220
    ) +
    ggplot2::scale_fill_gradientn(
      colors = style$palette$heatmap_fill,
      limits = c(0, 1),
      breaks = c(0),
      labels = c("0"),
      name = labels$legend_max,
      guide = ggplot2::guide_colorbar(
        title.position = "top",
        title.hjust = 0.5,
        ticks = FALSE,
        barheight = grid::unit(34, "mm"),
        barwidth = grid::unit(3.8, "mm")
      )
    )

  if (isTRUE(cfg$overlay_trajectory)) {
    p <- p +
      ggplot2::geom_path(
        data = track_df,
        ggplot2::aes(.data$x, .data$y, group = .data$.path_group),
        color = "#C8E5FF",
        linewidth = track_w * 0.6,
        alpha = 0.86,
        lineend = "round",
        inherit.aes = FALSE
      )
  }
  p
}

#' Plot water maze trajectories
#'
#' @param input CSV file path or standardized data frame.
#' @param cfg Configuration list.
#'
#' @return A ggplot object.
#' @export
plot_watermaze <- function(input, cfg = list()) {
  data <- if (is.character(input) && length(input) == 1) {
    read_mmviz_csv(input, task = "watermaze")
  } else {
    mmviz_validate_data(input, task = "watermaze")
  }
  cfg <- mmviz_merge_cfg(mmviz_default_cfg("watermaze"), cfg)

  data <- .mmviz_apply_python_backend(data, task = "watermaze")
  style <- theme_mmviz(mode = cfg$style_mode)
  geo <- .mmviz_estimate_pool_geometry(data, cfg)

  groups <- mmviz_reorder_groups(unique(data$group), cfg$group_order)
  if (length(groups) == 0) {
    stop("No groups found in data.", call. = FALSE)
  }

  plots <- lapply(groups, function(g) {
    .mmviz_build_watermaze_group_plot(
      df_group = dplyr::filter(data, .data$group == g),
      group_label = g,
      geo = geo,
      cfg = cfg,
      style = style
    )
  })

  panel_per_row <- as.integer(cfg$panel_per_row %||% 4L)
  panel_per_row <- max(1L, panel_per_row)
  panel_ncol <- min(panel_per_row, length(plots))
  panel_nrow <- ceiling(length(plots) / panel_ncol)

  if (is.null(cfg$figure_width)) {
    cfg$figure_width <- 4.6 * panel_ncol + 1.2
  }
  if (is.null(cfg$figure_height)) {
    cfg$figure_height <- 4.2 * panel_nrow + 1.1
  }

  panel_plot <- cowplot::plot_grid(
    plotlist = plots,
    nrow = panel_nrow,
    ncol = panel_ncol,
    align = "hv"
  )

  title_text <- cfg$title %||% mmviz_label("watermaze_title")
  title_plot <- cowplot::ggdraw() +
    cowplot::draw_label(
      title_text,
      x = 0.01,
      hjust = 0,
      fontface = "bold",
      size = 18,
      color = style$palette$text
    )

  out_plot <- cowplot::plot_grid(
    title_plot,
    panel_plot,
    ncol = 1,
    rel_heights = c(0.10, 0.90)
  )

  mmviz_save_plot(out_plot, cfg)
  out_plot
}
