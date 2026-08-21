.mmviz_guess_group_from_filename <- function(path) {
  stem <- tolower(.mmviz_infer_subject_from_path(path))
  if (grepl("^sham", stem)) return("Sham")
  if (grepl("^sah", stem)) return("SAH")
  if (grepl("^nmp", stem)) return("NMP")
  if (grepl("^nm", stem)) return("NM")
  if (grepl("^control", stem)) return("Control")
  if (grepl("^model", stem)) return("Model")
  stem
}

.mmviz_infer_subject_from_path <- function(path) {
  stem <- mmviz_safe_file_stem(path)
  # The author's acquisition export prefixes the subject with a known
  # non-ASCII label. Build it at runtime so package source remains portable.
  stem <- sub("^(watermaze|minefield)__", "", stem, ignore.case = TRUE, perl = TRUE)
  acquisition_prefix <- intToUtf8(c(0x8F68, 0x8FF9, 0x5750, 0x6807, 0x70B9))
  stem <- sub(paste0("^", acquisition_prefix), "", stem, perl = TRUE)
  stem <- sub("^(trajectory[_ -]*coordinates?|track[_ -]*coordinates?)[_ -]*", "", stem, ignore.case = TRUE, perl = TRUE)
  if (!nzchar(stem)) "plot" else stem
}

.mmviz_parse_legacy_track_csv <- function(path) {
  file_size <- file.info(path)$size
  if (is.na(file_size) || file_size <= 0) {
    return(NULL)
  }
  raw_vec <- readBin(path, what = "raw", n = file_size)
  raw_vec <- raw_vec[raw_vec != as.raw(0)]
  if (length(raw_vec) == 0) {
    return(NULL)
  }
  txt <- rawToChar(raw_vec)
  number <- "[+-]?(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?"
  pair_pattern <- paste0(
    "\"\\s*", number, "\\s*,\\s*", number, "\\s*\""
  )
  m <- gregexpr(pair_pattern, txt, perl = TRUE)
  hits <- regmatches(txt, m)[[1]]

  if (length(hits) >= 2) {
    remainder <- gsub(pair_pattern, "", txt, perl = TRUE)
    remainder <- gsub("[,;[:space:]]+", "", remainder, perl = TRUE)
    if (nzchar(remainder)) {
      return(NULL)
    }
    clean <- gsub("\"", "", hits, fixed = TRUE)
    xy <- strsplit(clean, ",", fixed = TRUE)
    mat <- do.call(rbind, xy)
  } else {
    two_col <- tryCatch(
      utils::read.table(
        text = txt,
        sep = ",",
        header = FALSE,
        colClasses = "character",
        stringsAsFactors = FALSE,
        strip.white = TRUE,
        comment.char = "",
        quote = "\""
      ),
      error = function(e) NULL
    )
    if (is.null(two_col) || ncol(two_col) != 2L || nrow(two_col) < 2L) {
      return(NULL)
    }
    mat <- as.matrix(two_col)
  }
  if (nrow(mat) < 2) {
    return(NULL)
  }

  x <- suppressWarnings(as.numeric(trimws(mat[, 1])))
  y <- suppressWarnings(as.numeric(trimws(mat[, 2])))
  if (any(is.na(x) | is.na(y) | !is.finite(x) | !is.finite(y))) {
    return(NULL)
  }

  df <- data.frame(
    subject_id = .mmviz_infer_subject_from_path(path),
    group = .mmviz_guess_group_from_filename(path),
    trial_id = "trial_1",
    frame = seq_len(nrow(mat)),
    x = x,
    y = y,
    stringsAsFactors = FALSE
  )
  df
}

.mmviz_clean_standard_csv <- function(df, path = NULL) {
  names(df) <- tolower(trimws(names(df)))
  required <- mmviz_required_columns()
  mmviz_assert_columns(df, required, object_name = sprintf("CSV `%s`", basename(path %||% "input")))

  # Keep known columns first, then preserve extra columns.
  known <- unique(c(required, mmviz_optional_columns()))
  keep <- c(intersect(known, names(df)), setdiff(names(df), known))
  df <- df[, keep, drop = FALSE]

  df <- mmviz_to_numeric_columns(df, c("frame", "x", "y"), object_name = "CSV data")
  df <- mmviz_assert_required_values(df, object_name = "CSV data")
  if ("time_sec" %in% names(df)) {
    df <- mmviz_to_numeric_columns(df, "time_sec", object_name = "CSV data")
    if (any(!is.finite(df$time_sec[!is.na(df$time_sec)]))) {
      stop("CSV data column `time_sec` must contain finite values.", call. = FALSE)
    }
  }

  if (nrow(df) == 0) {
    stop("CSV has no data rows.", call. = FALSE)
  }

  df <- dplyr::as_tibble(df)
  dplyr::arrange(df, .data$subject_id, .data$trial_id, .data$frame)
}

.mmviz_prepare_export_df <- function(data, include_optional = TRUE, keep_extra = FALSE) {
  required <- mmviz_required_columns()
  optional <- if (isTRUE(include_optional)) intersect(mmviz_optional_columns(), names(data)) else character(0)
  export_cols <- c(required, optional)
  if (isTRUE(keep_extra)) {
    extra <- setdiff(names(data), export_cols)
    export_cols <- c(export_cols, extra)
  }
  out <- data[, export_cols, drop = FALSE]
  as.data.frame(out, stringsAsFactors = FALSE)
}

#' Read standard CSV for watermaze or minefield tasks
#'
#' @param path CSV file path.
#' @param task One of `watermaze` or `minefield`.
#'
#' @return A tibble with standard columns.
#' @export
#' @examples
#' path <- system.file("templates", "watermaze_template.csv", package = "MMV")
#' data <- read_mmviz_csv(path, task = "watermaze")
#' head(data)
read_mmviz_csv <- function(path, task = c("watermaze", "minefield")) {
  task <- mmviz_normalize_task(task[1])
  path <- mmviz_assert_scalar_path(path, "path")
  if (!file.exists(path)) {
    stop(sprintf("Input file does not exist: %s", path), call. = FALSE)
  }

  # Standard schema first.
  standard <- tryCatch(
    suppressWarnings(utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)),
    error = function(e) e
  )

  standard_error <- NULL
  if (!inherits(standard, "error")) {
    parsed_standard <- tryCatch(
      .mmviz_clean_standard_csv(standard, path = path),
      error = function(e) e
    )
    if (!inherits(parsed_standard, "error")) {
      attr(parsed_standard, "task") <- task
      attr(parsed_standard, "source_format") <- "standard"
      return(parsed_standard)
    }
    standard_error <- parsed_standard
  } else {
    standard_error <- standard
  }

  # Legacy fallback for coordinate streams like: "233,135","232,133",...
  legacy <- .mmviz_parse_legacy_track_csv(path)
  if (!is.null(legacy)) {
    legacy <- dplyr::as_tibble(legacy)
    attr(legacy, "task") <- task
    attr(legacy, "source_format") <- "legacy"
    return(legacy)
  }

  stop(
    paste(
      sprintf("CSV parsing failed for `%s`.", basename(path)),
      sprintf("Standard-schema error: %s", conditionMessage(standard_error)),
      "Expected required columns:",
      paste(mmviz_required_columns(), collapse = ", "),
      "or legacy coordinate-stream format."
    ),
    call. = FALSE
  )
}

#' Convert one CSV into standardized mmviz schema
#'
#' @param path Input CSV file path (legacy or standard).
#' @param out_path Output CSV file path. Defaults to `<input_stem>_standard.csv`.
#' @param task One of `watermaze` or `minefield`.
#' @param overwrite Whether to overwrite an existing output file.
#' @param include_optional Whether to include optional columns (`time_sec`, `event`) when present.
#' @param keep_extra Whether to keep extra non-schema columns in output.
#' @param subject_id Optional override for all rows.
#' @param group Optional override for all rows.
#' @param trial_id Optional override for all rows.
#'
#' @return A one-row data frame with conversion metadata.
#' @export
#' @examples
#' source <- system.file("templates", "watermaze_template.csv", package = "MMV")
#' output <- tempfile(fileext = ".csv")
#' convert_mmviz_csv(source, output, overwrite = TRUE)
convert_mmviz_csv <- function(
  path,
  out_path = NULL,
  task = c("watermaze", "minefield"),
  overwrite = FALSE,
  include_optional = TRUE,
  keep_extra = FALSE,
  subject_id = NULL,
  group = NULL,
  trial_id = NULL
) {
  task <- mmviz_normalize_task(task[1])
  path <- mmviz_assert_scalar_path(path, "path")
  data <- read_mmviz_csv(path, task = task)

  if (!is.null(subject_id)) data$subject_id <- as.character(subject_id)
  if (!is.null(group)) data$group <- as.character(group)
  if (!is.null(trial_id)) data$trial_id <- as.character(trial_id)

  if (is.null(out_path)) {
    out_path <- file.path(
      dirname(path),
      paste0(mmviz_safe_file_stem(path), "_standard.csv")
    )
  }
  out_path <- mmviz_assert_scalar_path(as.character(out_path), "out_path")

  if (file.exists(out_path) && !isTRUE(overwrite)) {
    stop(sprintf("Output already exists (set overwrite = TRUE): %s", out_path), call. = FALSE)
  }

  out_dir <- dirname(out_path)
  if (!dir.exists(out_dir)) {
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  }
  if (!dir.exists(out_dir)) {
    stop(sprintf("Cannot create output directory: %s", out_dir), call. = FALSE)
  }

  export_df <- .mmviz_prepare_export_df(
    data = data,
    include_optional = include_optional,
    keep_extra = keep_extra
  )
  utils::write.csv(export_df, out_path, row.names = FALSE, na = "")

  data.frame(
    task = task,
    input_file = normalizePath(path, winslash = "/", mustWork = FALSE),
    output_file = normalizePath(out_path, winslash = "/", mustWork = FALSE),
    source_format = as.character(attr(data, "source_format") %||% "unknown"),
    rows = nrow(export_df),
    stringsAsFactors = FALSE
  )
}

#' Convert all CSVs in a folder into standardized mmviz schema
#'
#' @param input_dir Directory containing source CSV files.
#' @param out_dir Output directory for standardized CSV files.
#' @param task One of `watermaze` or `minefield`.
#' @param pattern File-matching regex for CSV discovery.
#' @param recursive Whether to search `input_dir` recursively. Subdirectory
#'   structure is preserved under `out_dir` to prevent filename collisions.
#' @param overwrite Whether to overwrite existing converted files.
#' @param include_optional Whether to include optional columns (`time_sec`, `event`) when present.
#' @param keep_extra Whether to keep extra non-schema columns in output.
#'
#' @return A data frame summarizing conversion status for each file.
#' @export
#' @examples
#' \dontrun{
#' convert_mmviz_folder("raw_tracks", "standard_tracks", recursive = TRUE)
#' }
convert_mmviz_folder <- function(
  input_dir,
  out_dir = file.path(input_dir, "converted_standard"),
  task = c("watermaze", "minefield"),
  pattern = "\\.csv$",
  recursive = FALSE,
  overwrite = FALSE,
  include_optional = TRUE,
  keep_extra = FALSE
) {
  task <- mmviz_normalize_task(task[1])
  input_dir <- mmviz_assert_scalar_path(input_dir, "input_dir")
  out_dir <- mmviz_assert_scalar_path(out_dir, "out_dir")
  if (!dir.exists(input_dir)) {
    stop(sprintf("Input directory does not exist: %s", input_dir), call. = FALSE)
  }

  files <- list.files(
    input_dir,
    pattern = pattern,
    full.names = TRUE,
    recursive = isTRUE(recursive),
    ignore.case = TRUE
  )
  files <- sort(unique(files))

  out_dir_norm <- normalizePath(out_dir, winslash = "/", mustWork = FALSE)
  files_norm <- normalizePath(files, winslash = "/", mustWork = FALSE)
  files <- files[!startsWith(files_norm, paste0(out_dir_norm, "/"))]

  if (length(files) == 0) {
    stop(sprintf("No files matched pattern `%s` in: %s", pattern, input_dir), call. = FALSE)
  }

  if (!dir.exists(out_dir)) {
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  }
  if (!dir.exists(out_dir)) {
    stop(sprintf("Cannot create output directory: %s", out_dir), call. = FALSE)
  }

  input_dir_norm <- normalizePath(input_dir, winslash = "/", mustWork = TRUE)

  rows <- vector("list", length(files))
  for (i in seq_along(files)) {
    src <- files[[i]]
    src_norm <- normalizePath(src, winslash = "/", mustWork = TRUE)
    relative <- if (startsWith(src_norm, paste0(input_dir_norm, "/"))) {
      substring(src_norm, nchar(input_dir_norm) + 2L)
    } else {
      basename(src_norm)
    }
    relative_dir <- dirname(relative)
    out_name <- paste0(mmviz_safe_file_stem(src), "_standard.csv")
    out_file <- if (identical(relative_dir, ".")) {
      file.path(out_dir, out_name)
    } else {
      file.path(out_dir, relative_dir, out_name)
    }

    status <- "ok"
    message <- ""
    rows_n <- NA_integer_
    source_format <- NA_character_
    output_file <- normalizePath(out_file, winslash = "/", mustWork = FALSE)

    tryCatch({
      res <- convert_mmviz_csv(
        path = src,
        out_path = out_file,
        task = task,
        overwrite = overwrite,
        include_optional = include_optional,
        keep_extra = keep_extra
      )
      rows_n <- as.integer(res$rows[[1]])
      source_format <- as.character(res$source_format[[1]])
    }, error = function(e) {
      status <<- "error"
      message <<- e$message
      output_file <<- NA_character_
    })

    rows[[i]] <- data.frame(
      task = task,
      input_file = normalizePath(src, winslash = "/", mustWork = FALSE),
      output_file = output_file,
      source_format = source_format,
      rows = rows_n,
      status = status,
      message = message,
      stringsAsFactors = FALSE
    )
  }

  dplyr::bind_rows(rows)
}

mmviz_validate_data <- function(data, task = c("watermaze", "minefield")) {
  task <- mmviz_normalize_task(task[1])
  if (!is.data.frame(data)) {
    stop("`data` must be a data.frame or tibble.", call. = FALSE)
  }

  names(data) <- tolower(trimws(names(data)))
  mmviz_assert_columns(data, mmviz_required_columns(), object_name = "data")
  data <- mmviz_to_numeric_columns(data, c("frame", "x", "y"), object_name = "data")
  data <- mmviz_assert_required_values(data, object_name = "data")

  if ("time_sec" %in% names(data)) {
    data <- mmviz_to_numeric_columns(data, "time_sec", object_name = "data")
    if (any(!is.finite(data$time_sec[!is.na(data$time_sec)]))) {
      stop("data column `time_sec` must contain finite values.", call. = FALSE)
    }
  }
  if (!"event" %in% names(data)) {
    data$event <- NA_character_
  }

  data <- dplyr::as_tibble(data)
  data <- dplyr::arrange(data, .data$subject_id, .data$trial_id, .data$frame)
  attr(data, "task") <- task
  data
}
