#' Enable or disable optional Python backend
#'
#' This package is R-first. Python is optional and accessed via reticulate.
#'
#' @param enable Logical, whether to enable python hooks.
#' @param module Optional Python module name. If NULL, uses `mmviz_backend`.
#'
#' @return (invisibly) backend state list.
#' @export
use_python_backend <- function(enable = FALSE, module = NULL) {
  .mmviz_state$python_enabled <- isTRUE(enable)
  if (is.null(module) || !nzchar(trimws(as.character(module)[1]))) {
    .mmviz_state$python_module <- NULL
  } else {
    .mmviz_state$python_module <- trimws(as.character(module)[1])
  }

  invisible(list(
    enable = .mmviz_state$python_enabled,
    module = .mmviz_state$python_module
  ))
}

.mmviz_apply_python_backend <- function(data, task = c("watermaze", "minefield")) {
  task <- mmviz_normalize_task(task[1])
  if (!isTRUE(.mmviz_state$python_enabled)) {
    return(data)
  }
  if (!requireNamespace("reticulate", quietly = TRUE)) {
    warning("Python backend is enabled but `reticulate` is not installed. Falling back to pure R.", call. = FALSE)
    return(data)
  }

  module_name <- .mmviz_state$python_module %||% "mmviz_backend"
  mod <- tryCatch(
    reticulate::import(module_name, delay_load = TRUE),
    error = function(e) {
      warning(
        sprintf("Cannot import Python module `%s`; fallback to pure R. Details: %s", module_name, e$message),
        call. = FALSE
      )
      NULL
    }
  )
  if (is.null(mod)) {
    return(data)
  }

  fn <- NULL
  if (reticulate::py_has_attr(mod, "postprocess_track")) {
    fn <- mod$postprocess_track
  } else if (reticulate::py_has_attr(mod, "postprocess")) {
    fn <- mod$postprocess
  }
  if (is.null(fn)) {
    warning(
      sprintf(
        "Python module `%s` has no `postprocess_track` or `postprocess`; fallback to pure R.",
        module_name
      ),
      call. = FALSE
    )
    return(data)
  }

  out <- tryCatch(
    fn(data, task = task),
    error = function(e) {
      warning(sprintf("Python postprocess failed; fallback to pure R. Details: %s", e$message), call. = FALSE)
      NULL
    }
  )
  if (is.null(out)) {
    return(data)
  }

  out_df <- tryCatch(as.data.frame(out, stringsAsFactors = FALSE), error = function(e) NULL)
  if (is.null(out_df)) {
    warning("Python output cannot be converted to data.frame; fallback to pure R.", call. = FALSE)
    return(data)
  }

  out_df <- mmviz_validate_data(out_df, task = task)
  out_df
}
