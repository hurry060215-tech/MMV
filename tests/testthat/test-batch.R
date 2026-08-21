test_that("plot_batch runs tasks from csv manifest", {
  td <- tempdir()
  water_csv <- file.path(td, "water.csv")
  mine_csv <- file.path(td, "mine.csv")
  manifest_csv <- file.path(td, "manifest.csv")
  out_dir <- file.path(td, "mmviz_out")

  writeLines(c(
    "subject_id,group,trial_id,frame,x,y",
    "s1,Sham,t1,1,100,100",
    "s1,Sham,t1,2,110,120",
    "s2,NM,t1,1,130,120",
    "s2,NM,t1,2,140,140"
  ), water_csv)

  writeLines(c(
    "subject_id,group,trial_id,frame,x,y",
    "m1,Control,t1,1,10,40",
    "m1,Control,t1,2,15,38",
    "m2,Model,t1,1,12,10",
    "m2,Model,t1,2,20,18"
  ), mine_csv)

  writeLines(c(
    "task,input,output_file,style_mode,plot_mode,overlay_trajectory",
    sprintf("watermaze,%s,water.png,builtin,line_gradient,FALSE", water_csv),
    sprintf("minefield,%s,mine.png,builtin,heatmap_only,TRUE", mine_csv)
  ), manifest_csv)

  res <- plot_batch(manifest = manifest_csv, out_dir = out_dir, cfg = list())
  expect_equal(nrow(res), 2)
  expect_true(all(res$status == "ok"))
  expect_true(all(file.exists(file.path(out_dir, c("water.png", "mine.png")))))
})

test_that("plot_batch resolves relative inputs and isolates bad rows", {
  td <- tempfile(pattern = "mmviz_batch_")
  dir.create(td, recursive = TRUE)
  on.exit(unlink(td, recursive = TRUE, force = TRUE), add = TRUE)

  input <- file.path(td, "water.csv")
  manifest <- file.path(td, "manifest.csv")
  out_dir <- file.path(td, "out")
  writeLines(c(
    "subject_id,group,trial_id,frame,x,y",
    "s1,Sham,t1,1,100,100",
    "s1,Sham,t1,2,110,120"
  ), input)
  writeLines(c(
    "task,input,output_file,style_mode,plot_mode,overlay_trajectory",
    "watermaze,water.csv,water.png,builtin,line_gradient,",
    "unknown,missing.csv,,,,"
  ), manifest)

  res <- plot_batch(manifest, out_dir)

  expect_equal(res$status, c("ok", "error"))
  expect_true(file.exists(file.path(out_dir, "water.png")))
  expect_match(res$message[2], "task.*watermaze, minefield")
})

test_that("plot_batch reports duplicate output paths without stopping other rows", {
  td <- tempfile(pattern = "mmviz_batch_duplicate_")
  dir.create(td, recursive = TRUE)
  on.exit(unlink(td, recursive = TRUE, force = TRUE), add = TRUE)

  input <- file.path(td, "water.csv")
  manifest <- file.path(td, "manifest.csv")
  out_dir <- file.path(td, "out")
  writeLines(c(
    "subject_id,group,trial_id,frame,x,y",
    "s1,Sham,t1,1,100,100",
    "s1,Sham,t1,2,110,120"
  ), input)
  writeLines(c(
    "task,input,output_file,style_mode,plot_mode,overlay_trajectory",
    "watermaze,water.csv,same.png,builtin,line_gradient,",
    "watermaze,water.csv,same.png,builtin,line_gradient,",
    "watermaze,water.csv,third.png,builtin,line_gradient,"
  ), manifest)

  res <- plot_batch(manifest, out_dir)

  expect_equal(res$status, c("ok", "error", "ok"))
  expect_match(res$message[2], "row 2.*duplicates row 1")
  expect_true(file.exists(file.path(out_dir, "same.png")))
  expect_true(file.exists(file.path(out_dir, "third.png")))
})
