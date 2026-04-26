.mmviz_extract_pkg_function <- function(package, fn_name) {
  if (!requireNamespace(package, quietly = TRUE)) {
    stop(sprintf("Package `%s` is not installed.", package), call. = FALSE)
  }
  ns <- asNamespace(package)
  if (!exists(fn_name, envir = ns, mode = "function", inherits = FALSE)) {
    stop(sprintf("Function `%s::%s` not found.", package, fn_name), call. = FALSE)
  }
  get(fn_name, envir = ns, mode = "function", inherits = FALSE)
}

#' Load full visualization runtime and extract package functions
#'
#' This helper explicitly loads runtime namespaces and can extract selected
#' functions from target packages while keeping original function environments.
#'
#' @param style_pkg Primary style package, default `thisplot`.
#' @param extra_pkgs Optional character vector of extra package names.
#' @param function_map Named list: package -> character vector of function names.
#' @param attach_packages Whether to attach packages to search path.
#'
#' @return A list with loaded packages, extracted functions, and a runtime env.
#' @export
load_visual_runtime <- function(
  style_pkg = "thisplot",
  extra_pkgs = NULL,
  function_map = list(),
  attach_packages = FALSE
) {
  packages <- unique(c(style_pkg, extra_pkgs))
  packages <- packages[nzchar(packages)]

  loaded <- character(0)
  for (pkg in packages) {
    ok <- requireNamespace(pkg, quietly = TRUE)
    if (!ok) next
    if (isTRUE(attach_packages)) {
      suppressPackageStartupMessages(
        library(pkg, character.only = TRUE)
      )
    }
    loaded <- c(loaded, pkg)
  }

  extracted <- list()
  runtime_env <- new.env(parent = baseenv())

  if (length(function_map) > 0) {
    for (pkg in names(function_map)) {
      fns <- as.character(function_map[[pkg]])
      if (!pkg %in% loaded) next
      for (fn_name in fns) {
        fn_obj <- tryCatch(
          .mmviz_extract_pkg_function(pkg, fn_name),
          error = function(e) NULL
        )
        if (is.null(fn_obj)) next
        key <- paste(pkg, fn_name, sep = "::")
        extracted[[key]] <- fn_obj
        assign(fn_name, fn_obj, envir = runtime_env)
      }
    }
  }

  list(
    packages_loaded = loaded,
    extracted_functions = extracted,
    runtime_env = runtime_env
  )
}
