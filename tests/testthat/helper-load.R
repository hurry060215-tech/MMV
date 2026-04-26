pkg_root <- normalizePath(
  file.path(testthat::test_path(), "..", ".."),
  winslash = "/",
  mustWork = TRUE
)

r_dir <- file.path(pkg_root, "R")
r_files <- sort(list.files(r_dir, pattern = "\\.R$", full.names = TRUE))
invisible(lapply(r_files, source, local = FALSE))
