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
