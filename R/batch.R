.mmviz_read_manifest <- function(manifest) {
  if (is.data.frame(manifest)) {
    return(manifest)
  }
  if (!is.character(manifest) || length(manifest) != 1) {
    stop("`manifest` must be a data.frame or a file path.", call. = FALSE)
  }
  if (!file.exists(manifest)) {
    stop(sprintf("Manifest file does not exist: %s", manifest), call. = FALSE)
  }

  ext <- tolower(tools::file_ext(manifest))
  if (ext == "csv") {
    out <- utils::read.csv(manifest, stringsAsFactors = FALSE, check.names = FALSE)
    return(out)
  }
  if (ext %in% c("yml", "yaml")) {
    if (!requireNamespace("yaml", quietly = TRUE)) {
      stop("Manifest is YAML but package `yaml` is not installed.", call. = FALSE)
    }
    y <- yaml::read_yaml(manifest)
    if (is.data.frame(y)) {
      return(y)
    }
    if (is.list(y$jobs)) {
      return(dplyr::bind_rows(y$jobs))
    }
    stop("YAML manifest must be a data.frame-like list or include a `jobs` list.", call. = FALSE)
  }
  stop("Unsupported manifest extension. Use CSV or YAML.", call. = FALSE)
}

.mmviz_apply_row_cfg <- function(base_cfg, row_df) {
  out <- base_cfg
  ignored <- c("task", "input", "output_file")
  for (nm in names(row_df)) {
    if (nm %in% ignored) next
    out[[nm]] <- mmviz_parse_scalar(row_df[[nm]][1])
  }
  out
}

#' Batch plotting from manifest
#'
#' @param manifest Data frame or path to CSV/YAML manifest.
#' @param out_dir Output directory.
#' @param cfg Base config list.
#'
#' @return A data frame with run status and output paths.
#' @export
plot_batch <- function(manifest, out_dir, cfg = list()) {
  manifest_df <- .mmviz_read_manifest(manifest)
  names(manifest_df) <- tolower(trimws(names(manifest_df)))
  mmviz_assert_columns(manifest_df, c("task", "input"), object_name = "manifest")

  if (!dir.exists(out_dir)) {
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  }

  results <- vector("list", nrow(manifest_df))
  for (i in seq_len(nrow(manifest_df))) {
    row <- manifest_df[i, , drop = FALSE]
    task <- mmviz_normalize_task(row$task[1])
    input <- as.character(row$input[1])

    row_cfg <- mmviz_merge_cfg(mmviz_default_cfg(task), cfg)
    row_cfg <- .mmviz_apply_row_cfg(row_cfg, row)

    out_name <- row$output_file[1] %||% NULL
    if (is.null(out_name) || !nzchar(trimws(as.character(out_name)))) {
      ext <- tolower(as.character(row_cfg$output_format %||% "png"))
      stem <- mmviz_safe_file_stem(input)
      out_name <- sprintf("%s_%02d_%s.%s", task, i, stem, ext)
    }
    row_cfg$out_file <- file.path(out_dir, as.character(out_name))

    status <- "ok"
    message <- ""
    output_path <- row_cfg$out_file

    tryCatch({
      if (task == "watermaze") {
        plot_watermaze(input, cfg = row_cfg)
      } else {
        plot_minefield(input, cfg = row_cfg)
      }
    }, error = function(e) {
      status <<- "error"
      message <<- e$message
      output_path <<- NA_character_
    })

    results[[i]] <- data.frame(
      row_id = i,
      task = task,
      input = input,
      output_file = output_path,
      status = status,
      message = message,
      stringsAsFactors = FALSE
    )
  }

  dplyr::bind_rows(results)
}
