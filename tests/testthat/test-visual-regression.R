test_that("real-data figures have deterministic SVG references", {
  fixture_dir <- test_path("fixtures", "real")
  source_files <- list.files(
    fixture_dir,
    pattern = "\\.csv$",
    full.names = TRUE
  )
  source_files <- source_files[!grepl("expectations|manifest", basename(source_files), ignore.case = TRUE)]
  skip_if(length(source_files) < 3L, "Real-data fixtures are pending author-provided files.")
  skip_if(
    sum(grepl("^watermaze__", basename(source_files))) < 2L ||
      sum(grepl("^minefield__", basename(source_files))) < 1L,
    "The required two water-maze plus one minefield fixture mix is incomplete."
  )
  skip_if_not(
    requireNamespace("vdiffr", quietly = TRUE),
    "vdiffr is required for SVG visual regression tests."
  )

  for (path in source_files) {
    task <- if (grepl("^watermaze__", basename(path))) {
      "watermaze"
    } else if (grepl("^minefield__", basename(path))) {
      "minefield"
    } else {
      next
    }
    cfg <- list(style_mode = "builtin", figure_width = 6, figure_height = 5)
    plot <- if (task == "watermaze") {
      plot_watermaze(path, cfg = cfg)
    } else {
      plot_minefield(path, cfg = cfg)
    }
    vdiffr::expect_doppelganger(
      paste0("real-", tools::file_path_sans_ext(basename(path))),
      plot
    )
  }
})
