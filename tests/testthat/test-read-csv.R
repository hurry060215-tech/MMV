test_that("read_mmviz_csv parses standard schema", {
  f <- tempfile(fileext = ".csv")
  on.exit(unlink(f), add = TRUE)

  writeLines(c(
    "subject_id,group,trial_id,frame,x,y",
    "s1,Sham,t1,1,10,20",
    "s1,Sham,t1,2,12,21"
  ), f)

  dat <- read_mmviz_csv(f, task = "watermaze")
  expect_s3_class(dat, "tbl_df")
  expect_true(all(mmviz_required_columns() %in% names(dat)))
  expect_equal(nrow(dat), 2)
})

test_that("read_mmviz_csv rejects invalid standard schema", {
  f <- tempfile(fileext = ".csv")
  on.exit(unlink(f), add = TRUE)

  writeLines(c(
    "subject_id,group,trial_id,x,y",
    "s1,Sham,t1,10,20"
  ), f)

  expect_error(read_mmviz_csv(f, task = "watermaze"), "Expected required columns|parsing failed")
})

test_that("read_mmviz_csv supports legacy coordinate stream", {
  f <- tempfile(fileext = ".csv")
  on.exit(unlink(f), add = TRUE)

  writeChar("\"10,20\",\"11,22\",\"13,24\"", f, eos = NULL, useBytes = TRUE)
  dat <- read_mmviz_csv(f, task = "watermaze")
  expect_true(all(mmviz_required_columns() %in% names(dat)))
  expect_true(nrow(dat) >= 2)
})

test_that("convert_mmviz_csv writes standardized output", {
  src <- tempfile(fileext = ".csv")
  out <- tempfile(fileext = ".csv")
  on.exit(unlink(c(src, out), force = TRUE), add = TRUE)

  writeChar("\"10,20\",\"11,22\",\"13,24\"", src, eos = NULL, useBytes = TRUE)
  res <- convert_mmviz_csv(src, out_path = out, task = "watermaze", overwrite = TRUE)

  expect_true(file.exists(out))
  expect_equal(res$source_format[[1]], "legacy")
  converted <- utils::read.csv(out, stringsAsFactors = FALSE)
  expect_true(all(mmviz_required_columns() %in% names(converted)))
  expect_equal(nrow(converted), 3)
})

test_that("convert_mmviz_folder converts multiple csv files", {
  in_dir <- tempfile(pattern = "mmviz_in_")
  out_dir <- tempfile(pattern = "mmviz_out_")
  dir.create(in_dir, recursive = TRUE)
  on.exit(unlink(c(in_dir, out_dir), recursive = TRUE, force = TRUE), add = TRUE)

  writeChar("\"1,1\",\"2,2\"", file.path(in_dir, "sham--1.csv"), eos = NULL, useBytes = TRUE)
  writeChar("\"3,3\",\"4,4\"", file.path(in_dir, "nm--2.csv"), eos = NULL, useBytes = TRUE)

  res <- convert_mmviz_folder(
    input_dir = in_dir,
    out_dir = out_dir,
    task = "watermaze",
    overwrite = TRUE
  )

  expect_equal(nrow(res), 2)
  expect_true(all(res$status == "ok"))
  expect_true(all(file.exists(res$output_file)))
})
