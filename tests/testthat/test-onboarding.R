test_that("mmviz_init creates a runnable starter project", {
  project_dir <- tempfile(pattern = "MMV-project-")
  on.exit(unlink(project_dir, recursive = TRUE, force = TRUE), add = TRUE)

  project <- mmviz_init(project_dir, quiet = TRUE)

  expect_true(dir.exists(project$project_dir))
  expect_true(file.exists(project$manifest))
  expect_true(file.exists(project$run_script))
  expect_true(file.exists(file.path(project_dir, "data", "watermaze.csv")))
  expect_true(file.exists(file.path(project_dir, "data", "minefield.csv")))

  old_wd <- setwd(tempdir())
  on.exit(setwd(old_wd), add = TRUE)
  invisible(capture.output(
    source(project$run_script, local = new.env(parent = globalenv()))
  ))

  expect_true(file.exists(file.path(project$output_dir, "watermaze.png")))
  expect_true(file.exists(file.path(project$output_dir, "minefield.png")))
})

test_that("mmviz_init refuses accidental overwrite and preserves other files", {
  project_dir <- tempfile(pattern = "MMV-project-")
  on.exit(unlink(project_dir, recursive = TRUE, force = TRUE), add = TRUE)

  mmviz_init(project_dir, quiet = TRUE)
  sentinel <- file.path(project_dir, "keep-me.txt")
  writeLines("keep", sentinel)

  expect_error(mmviz_init(project_dir, quiet = TRUE), "already exist")
  mmviz_init(project_dir, overwrite = TRUE, quiet = TRUE)
  expect_true(file.exists(sentinel))
  expect_equal(readLines(sentinel), "keep")
})

test_that("plot_mmviz delegates both tasks and supports out_file", {
  water <- system.file("templates", "watermaze_template.csv", package = "MMV")
  mine <- system.file("templates", "minefield_template.csv", package = "MMV")
  water_out <- tempfile(fileext = ".png")
  mine_out <- tempfile(fileext = ".png")
  on.exit(unlink(c(water_out, mine_out), force = TRUE), add = TRUE)

  water_plot <- plot_mmviz(
    water,
    task = "watermaze",
    cfg = list(style_mode = "builtin"),
    out_file = water_out
  )
  mine_plot <- plot_mmviz(
    mine,
    task = "minefield",
    cfg = list(style_mode = "builtin"),
    out_file = mine_out
  )

  expect_s3_class(water_plot, "ggplot")
  expect_s3_class(mine_plot, "ggplot")
  expect_true(file.exists(water_out))
  expect_true(file.exists(mine_out))
  expect_error(plot_mmviz(water, task = "unknown"), "watermaze, minefield")
})
