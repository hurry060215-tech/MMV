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
    value <- mmviz_parse_scalar(row_df[[nm]][1])
    if (!is.null(value)) {
      out[[nm]] <- value
    }
  }
  out
}

#' Batch plotting from manifest
#'
#' @param manifest Data frame or path to a CSV/YAML manifest. Relative input
#'   paths in a file manifest are resolved from the manifest's directory.
#' @param out_dir Output directory.
#' @param cfg Base config list.
#'
#' @return A data frame with one `ok` or `error` status per job. A failed job
#'   does not stop later jobs.
#' @export
#' @examples
#' manifest <- system.file("templates", "manifest_template.csv", package = "MMV")
#' result <- plot_batch(manifest, file.path(tempdir(), "MMV-batch"))
#' result[, c("task", "status")]
plot_batch <- function(manifest, out_dir, cfg = list()) {
  manifest_df <- .mmviz_read_manifest(manifest)
  names(manifest_df) <- tolower(trimws(names(manifest_df)))
  mmviz_assert_columns(manifest_df, c("task", "input"), object_name = "manifest")
  if (nrow(manifest_df) == 0L) {
    stop("Manifest has no job rows.", call. = FALSE)
  }

  out_dir <- mmviz_assert_scalar_path(out_dir, "out_dir")
  manifest_dir <- if (is.character(manifest) && length(manifest) == 1L) {
    dirname(normalizePath(manifest, winslash = "/", mustWork = TRUE))
  } else {
    getwd()
  }

  if (!dir.exists(out_dir)) {
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  }
  if (!dir.exists(out_dir)) {
    stop(sprintf("Cannot create output directory: %s", out_dir), call. = FALSE)
  }

  results <- vector("list", nrow(manifest_df))
  for (i in seq_len(nrow(manifest_df))) {
    row <- manifest_df[i, , drop = FALSE]
    task_raw <- as.character(row$task[1])
    input_raw <- as.character(row$input[1])

    results[[i]] <- tryCatch({
      task <- mmviz_normalize_task(task_raw)
      input_raw <- mmviz_assert_scalar_path(input_raw, "manifest input")
      input <- if (mmviz_is_absolute_path(input_raw)) {
        input_raw
      } else {
        file.path(manifest_dir, input_raw)
      }

      row_cfg <- mmviz_merge_cfg(mmviz_default_cfg(task), cfg)
      row_cfg <- .mmviz_apply_row_cfg(row_cfg, row)

      out_name <- if ("output_file" %in% names(row)) {
        mmviz_parse_scalar(row$output_file[1])
      } else {
        NULL
      }
      if (is.null(out_name)) {
        ext <- tolower(as.character(row_cfg$output_format %||% "png"))
        stem <- mmviz_safe_file_stem(input)
        out_name <- sprintf("%s_%02d_%s.%s", task, i, stem, ext)
      }
      out_name <- mmviz_assert_scalar_path(as.character(out_name), "output_file")
      row_cfg$out_file <- if (mmviz_is_absolute_path(out_name)) {
        out_name
      } else {
        file.path(out_dir, out_name)
      }

      if (task == "watermaze") {
        plot_watermaze(input, cfg = row_cfg)
      } else {
        plot_minefield(input, cfg = row_cfg)
      }
      data.frame(
        row_id = i,
        task = task,
        input = normalizePath(input, winslash = "/", mustWork = FALSE),
        output_file = normalizePath(
          row_cfg$out_file,
          winslash = "/",
          mustWork = FALSE
        ),
        status = "ok",
        message = "",
        stringsAsFactors = FALSE
      )
    }, error = function(e) {
      data.frame(
        row_id = i,
        task = task_raw,
        input = input_raw,
        output_file = NA_character_,
        status = "error",
        message = conditionMessage(e),
        stringsAsFactors = FALSE
      )
    })
  }

  dplyr::bind_rows(results)
}
