#' Initialize a ready-to-run MMV project
#'
#' Creates a small project containing editable water-maze and minefield CSV
#' files, a batch manifest, an output directory, and a standalone `run_mmviz.R`
#' script. Existing unrelated files are never removed.
#'
#' @param path Directory to create.
#' @param overwrite Whether to replace MMV-managed starter files that already
#'   exist. The default is `FALSE`.
#' @param quiet Whether to suppress the success message.
#'
#' @return A one-row data frame containing normalized project paths.
#' @export
#' @examples
#' project <- mmviz_init(tempfile("MMV-project-"), quiet = TRUE)
#' file.exists(project$run_script)
mmviz_init <- function(path = "MMV-project", overwrite = FALSE, quiet = FALSE) {
  path <- mmviz_assert_scalar_path(path, "path")
  if (!is.logical(overwrite) || length(overwrite) != 1L || is.na(overwrite)) {
    stop("`overwrite` must be TRUE or FALSE.", call. = FALSE)
  }
  if (!is.logical(quiet) || length(quiet) != 1L || is.na(quiet)) {
    stop("`quiet` must be TRUE or FALSE.", call. = FALSE)
  }

  project_dir <- normalizePath(path, winslash = "/", mustWork = FALSE)
  data_dir <- file.path(project_dir, "data")
  output_dir <- file.path(project_dir, "outputs")
  managed <- c(
    file.path(data_dir, "watermaze.csv"),
    file.path(data_dir, "minefield.csv"),
    file.path(project_dir, "manifest.csv"),
    file.path(project_dir, "run_mmviz.R"),
    file.path(project_dir, "README.md")
  )
  existing <- managed[file.exists(managed)]
  if (length(existing) > 0L && !overwrite) {
    stop(
      paste0(
        "MMV starter files already exist (set overwrite = TRUE to replace them): ",
        paste(basename(existing), collapse = ", ")
      ),
      call. = FALSE
    )
  }

  water_template <- system.file(
    "templates",
    "watermaze_template.csv",
    package = "MMV"
  )
  mine_template <- system.file(
    "templates",
    "minefield_template.csv",
    package = "MMV"
  )
  if (!nzchar(water_template) || !nzchar(mine_template)) {
    stop("Installed MMV templates could not be found.", call. = FALSE)
  }

  # Keep a byte-for-byte backup of managed files so a failed copy/write never
  # leaves a half-generated starter project behind. Unrelated files and
  # pre-existing directories are intentionally not touched.
  backups <- list()
  for (file in existing) {
    size <- file.info(file)$size
    backups[[file]] <- if (isTRUE(size > 0)) {
      readBin(file, what = "raw", n = size)
    } else {
      raw(0)
    }
  }
  created_files <- character(0)
  created_dirs <- character(0)
  rollback <- function() {
    for (file in created_files) {
      if (file.exists(file)) unlink(file, force = TRUE)
    }
    for (file in names(backups)) {
      writeBin(backups[[file]], file)
    }
    for (directory in rev(created_dirs)) {
      if (dir.exists(directory) && length(list.files(directory, all.files = TRUE)) <= 2L) {
        unlink(directory, recursive = TRUE, force = TRUE)
      }
    }
  }

  tryCatch({
    for (directory in c(project_dir, data_dir, output_dir)) {
      if (!dir.exists(directory)) {
        dir.create(directory, recursive = TRUE, showWarnings = FALSE)
        created_dirs <- c(created_dirs, directory)
      }
      if (!dir.exists(directory)) {
        stop(sprintf("Cannot create directory: %s", directory), call. = FALSE)
      }
    }

    copied <- vapply(seq_along(managed[1:2]), function(i) {
      ok <- file.copy(
        c(water_template, mine_template)[[i]],
        managed[1:2][[i]],
        overwrite = overwrite
      )
      if (isTRUE(ok) && !managed[1:2][[i]] %in% existing) {
        created_files <<- c(created_files, managed[1:2][[i]])
      }
      ok
    }, logical(1))
    if (!all(copied)) {
      stop("Could not copy one or more MMV data templates.", call. = FALSE)
    }

    writeLines(
      c(
        "task,input,output_file,style_mode,plot_mode,overlay_trajectory",
        "watermaze,data/watermaze.csv,watermaze.png,builtin,line_gradient,FALSE",
        "minefield,data/minefield.csv,minefield.png,builtin,heatmap_only,TRUE"
      ),
      managed[3],
      useBytes = TRUE
    )
    if (!managed[3] %in% existing) created_files <- c(created_files, managed[3])
    writeLines(.mmviz_starter_script(), managed[4], useBytes = TRUE)
    if (!managed[4] %in% existing) created_files <- c(created_files, managed[4])
    writeLines(.mmviz_starter_readme(), managed[5], useBytes = TRUE)
    if (!managed[5] %in% existing) created_files <- c(created_files, managed[5])
  }, error = function(e) {
    rollback()
    stop(sprintf("Could not initialize MMV project: %s", conditionMessage(e)), call. = FALSE)
  })

  project_dir_display <- normalizePath(
    project_dir,
    winslash = "/",
    mustWork = TRUE
  )
  result <- data.frame(
    project_dir = project_dir_display,
    manifest = normalizePath(managed[3], winslash = "/", mustWork = TRUE),
    run_script = normalizePath(managed[4], winslash = "/", mustWork = TRUE),
    output_dir = normalizePath(output_dir, winslash = "/", mustWork = TRUE),
    stringsAsFactors = FALSE
  )
  if (!quiet) {
    message(
      "MMV project created at ",
      project_dir_display,
      "\nRun: Rscript \"",
      result$run_script,
      "\""
    )
  }
  result
}

.mmviz_starter_script <- function() {
  c(
    "library(MMV)",
    "",
    "source_files <- vapply(sys.frames(), function(frame) {",
    "  value <- frame$ofile",
    "  if (is.null(value)) NA_character_ else as.character(value)[1]",
    "}, character(1))",
    "source_files <- source_files[!is.na(source_files) & nzchar(source_files)]",
    "args <- commandArgs(trailingOnly = FALSE)",
    "file_arg <- sub('^--file=', '', args[grepl('^--file=', args)])",
    "if (length(source_files) > 0L) {",
    "  project_dir <- dirname(normalizePath(tail(source_files, 1L)))",
    "} else if (length(file_arg) > 0L) {",
    "  project_dir <- dirname(normalizePath(file_arg[1]))",
    "} else {",
    "  project_dir <- getwd()",
    "}",
    "",
    "result <- plot_batch(",
    "  manifest = file.path(project_dir, 'manifest.csv'),",
    "  out_dir = file.path(project_dir, 'outputs')",
    ")",
    "print(result)",
    "if (any(result$status == 'error')) {",
    "  stop('One or more MMV jobs failed; inspect the result table above.')",
    "}"
  )
}

.mmviz_starter_readme <- function() {
  c(
    "# My MMV project",
    "",
    "1. Replace the sample rows in `data/watermaze.csv` or `data/minefield.csv`.",
    "2. Edit `manifest.csv` to choose inputs, output names, and plot modes.",
    "3. Run `Rscript run_mmviz.R` from any working directory.",
    "4. Find generated figures in `outputs/`.",
    "",
    "Required CSV columns: `subject_id`, `group`, `trial_id`, `frame`, `x`, `y`.",
    "Optional columns: `time_sec`, `event`."
  )
}

#' Plot an MMV task through one unified entry point
#'
#' This convenience wrapper delegates to [plot_watermaze()] or
#' [plot_minefield()] and returns the same ggplot object.
#'
#' @param input CSV file path or standardized data frame.
#' @param task Either `"watermaze"` or `"minefield"`.
#' @param cfg Configuration list accepted by the task-specific plotter.
#' @param out_file Optional output path. When supplied, it overrides
#'   `cfg$out_file`.
#'
#' @return A ggplot object.
#' @export
#' @examples
#' path <- system.file("templates", "watermaze_template.csv", package = "MMV")
#' plot_mmviz(path, task = "watermaze", cfg = list(style_mode = "builtin"))
plot_mmviz <- function(input, task, cfg = list(), out_file = NULL) {
  task <- mmviz_normalize_task(task)
  if (!is.list(cfg)) {
    stop("`cfg` must be a list.", call. = FALSE)
  }
  if (!is.null(out_file)) {
    cfg$out_file <- mmviz_assert_scalar_path(out_file, "out_file")
  }
  if (task == "watermaze") {
    plot_watermaze(input, cfg = cfg)
  } else {
    plot_minefield(input, cfg = cfg)
  }
}
