.mmviz_estimate_field_geometry <- function(data, cfg) {
  xlim_cfg <- cfg$field_xlim %||% NULL
  ylim_cfg <- cfg$field_ylim %||% NULL

  if (!is.null(xlim_cfg) && length(xlim_cfg) == 2 && all(is.finite(as.numeric(xlim_cfg)))) {
    xlim <- as.numeric(xlim_cfg)
  } else {
    x_q <- stats::quantile(data$x, probs = c(0.005, 0.995), na.rm = TRUE)
    x_pad <- 0.04 * diff(x_q)
    xlim <- c(x_q[1] - x_pad, x_q[2] + x_pad)
  }

  if (!is.null(ylim_cfg) && length(ylim_cfg) == 2 && all(is.finite(as.numeric(ylim_cfg)))) {
    ylim <- as.numeric(ylim_cfg)
  } else {
    y_q <- stats::quantile(data$y, probs = c(0.005, 0.995), na.rm = TRUE)
    y_pad <- 0.04 * diff(y_q)
    ylim <- c(y_q[1] - y_pad, y_q[2] + y_pad)
  }

  list(xlim = xlim, ylim = ylim)
}

.mmviz_build_minefield_group_plot <- function(df_group, group_label, field_geo, cfg, style) {
  labels <- list(legend_density = mmviz_label("legend_density"))
  bg_col <- cfg$background_color %||% style$palette$bg_minefield
  guide_col <- cfg$guide_color %||% style$palette$guide
  mode <- tolower(as.character(cfg$plot_mode %||% "heatmap_only"))
  track_w <- as.numeric(cfg$track_linewidth %||% 0.7)

  track_df <- df_group %>%
    dplyr::arrange(.data$subject_id, .data$trial_id, .data$frame) %>%
    dplyr::group_by(.data$subject_id, .data$trial_id) %>%
    dplyr::mutate(
      .path_group = paste0(.data$subject_id, "::", .data$trial_id),
      .frame01 = (dplyr::row_number() - 1) / pmax(dplyr::n() - 1, 1)
    ) %>%
    dplyr::ungroup()

  p <- ggplot2::ggplot() +
    ggplot2::annotate(
      "rect",
      xmin = field_geo$xlim[1],
      xmax = field_geo$xlim[2],
      ymin = field_geo$ylim[1],
      ymax = field_geo$ylim[2],
      fill = bg_col
    ) +
    ggplot2::stat_density_2d(
      data = track_df,
      ggplot2::aes(.data$x, .data$y, fill = ggplot2::after_stat(.data$ndensity)),
      geom = "raster",
      contour = FALSE,
      n = 240
    ) +
    ggplot2::scale_fill_gradientn(
      colors = style$palette$mine_heatmap,
      limits = c(0, 1),
      name = labels$legend_density,
      guide = ggplot2::guide_colorbar(
        title.position = "top",
        title.hjust = 0.5,
        ticks = FALSE,
        barheight = grid::unit(32, "mm"),
        barwidth = grid::unit(4, "mm")
      )
    ) +
    ggplot2::coord_cartesian(
      xlim = field_geo$xlim,
      ylim = rev(field_geo$ylim),
      expand = FALSE
    ) +
    ggplot2::labs(title = group_label) +
    style$gg_theme +
    ggplot2::theme(
      panel.background = ggplot2::element_rect(fill = bg_col, color = guide_col, linewidth = 0.5),
      plot.background = ggplot2::element_rect(fill = "white", color = NA),
      plot.title = ggplot2::element_text(size = 13, hjust = 0.5, face = "bold"),
      legend.position = "right",
      legend.title = ggplot2::element_text(size = 10),
      legend.text = ggplot2::element_text(size = 9),
      plot.margin = ggplot2::margin(4, 4, 4, 4)
    )

  if (isTRUE(cfg$overlay_trajectory) || mode == "heatmap_with_trajectory") {
    p <- p +
      ggplot2::geom_path(
        data = track_df,
        ggplot2::aes(.data$x, .data$y, group = .data$.path_group),
        color = "#DDEAFF",
        linewidth = track_w * 1.2,
        alpha = 0.25,
        lineend = "round",
        inherit.aes = FALSE
      ) +
      ggplot2::geom_path(
        data = track_df,
        ggplot2::aes(.data$x, .data$y, group = .data$.path_group, color = .data$.frame01),
        linewidth = track_w,
        alpha = 0.85,
        lineend = "round",
        inherit.aes = FALSE,
        show.legend = FALSE
      ) +
      ggplot2::scale_color_gradientn(colors = style$palette$line_gradient, guide = "none")
  }
  p
}

#' Plot minefield heatmap
#'
#' @param input CSV file path or standardized data frame.
#' @param cfg Configuration list.
#'
#' @return A ggplot object.
#' @export
plot_minefield <- function(input, cfg = list()) {
  data <- if (is.character(input) && length(input) == 1) {
    read_mmviz_csv(input, task = "minefield")
  } else {
    mmviz_validate_data(input, task = "minefield")
  }
  cfg <- mmviz_merge_cfg(mmviz_default_cfg("minefield"), cfg)

  data <- .mmviz_apply_python_backend(data, task = "minefield")
  style <- theme_mmviz(mode = cfg$style_mode)
  geo <- .mmviz_estimate_field_geometry(data, cfg)

  groups <- mmviz_reorder_groups(unique(data$group), cfg$group_order)
  if (length(groups) == 0) {
    stop("No groups found in data.", call. = FALSE)
  }

  plots <- lapply(groups, function(g) {
    .mmviz_build_minefield_group_plot(
      df_group = dplyr::filter(data, .data$group == g),
      group_label = g,
      field_geo = geo,
      cfg = cfg,
      style = style
    )
  })

  panel_per_row <- as.integer(cfg$panel_per_row %||% 4L)
  panel_per_row <- max(1L, panel_per_row)
  panel_ncol <- min(panel_per_row, length(plots))
  panel_nrow <- ceiling(length(plots) / panel_ncol)

  if (is.null(cfg$figure_width)) {
    cfg$figure_width <- 4.8 * panel_ncol + 1.0
  }
  if (is.null(cfg$figure_height)) {
    cfg$figure_height <- 4.0 * panel_nrow + 1.0
  }

  panel_plot <- cowplot::plot_grid(
    plotlist = plots,
    nrow = panel_nrow,
    ncol = panel_ncol,
    align = "hv"
  )

  title_text <- cfg$title %||% mmviz_label("minefield_title")
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
