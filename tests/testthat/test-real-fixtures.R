test_that("redistributable real-data fixtures satisfy schema and geometry intake", {
  fixture_dir <- test_path("fixtures", "real")
  provenance <- file.path(fixture_dir, "PROVENANCE.md")
  skip_if(
    !file.exists(provenance),
    "Real-data provenance is pending author confirmation."
  )
  files <- list.files(fixture_dir, pattern = "\\.csv$", full.names = TRUE)
  source_files <- files[!grepl("expectations|manifest", basename(files), ignore.case = TRUE)]
  skip_if(
    length(source_files) < 3L,
    "Real-data fixtures are pending author-provided anonymous files and permission."
  )

  water <- source_files[grepl("^watermaze__", basename(source_files))]
  mine <- source_files[grepl("^minefield__", basename(source_files))]
  skip_if(
    length(water) < 2L || length(mine) < 1L,
    "The required two water-maze plus one minefield fixture mix is incomplete."
  )

  for (path in source_files) {
    task <- if (grepl("^watermaze__", basename(path))) {
      "watermaze"
    } else if (grepl("^minefield__", basename(path))) {
      "minefield"
    } else {
      next
    }
    data <- read_mmviz_csv(path, task = task)
    expect_gte(nrow(data), 2L, info = basename(path))
    expect_true(all(is.finite(data$x)), info = basename(path))
    expect_true(all(is.finite(data$y)), info = basename(path))
    expect_true(all(nzchar(as.character(data$subject_id))), info = basename(path))
    expect_true(all(nzchar(as.character(data$group))), info = basename(path))

    converted <- convert_mmviz_csv(
      path,
      out_path = tempfile(fileext = ".csv"),
      task = task,
      overwrite = TRUE
    )
    expect_equal(converted$rows[[1]], nrow(data), info = basename(path))
  }

  expectations <- file.path(fixture_dir, "geometry_expectations.csv")
  if (file.exists(expectations)) {
    golden <- utils::read.csv(expectations, stringsAsFactors = FALSE)
    expect_true(all(c("fixture", "rows", "x_min", "x_max", "y_min", "y_max") %in% names(golden)))
    for (i in seq_len(nrow(golden))) {
      path <- file.path(fixture_dir, golden$fixture[[i]])
      dat <- read_mmviz_csv(path, task = if (grepl("^watermaze__", golden$fixture[[i]])) "watermaze" else "minefield")
      expect_equal(nrow(dat), golden$rows[[i]], info = golden$fixture[[i]])
      expect_equal(range(dat$x), c(golden$x_min[[i]], golden$x_max[[i]]), info = golden$fixture[[i]])
      expect_equal(range(dat$y), c(golden$y_min[[i]], golden$y_max[[i]]), info = golden$fixture[[i]])
    }
  }
})
