test_that("plot_watermaze works and saves output", {
  dat <- data.frame(
    subject_id = rep(c("rat1", "rat2"), each = 12),
    group = rep(c("Sham", "NM"), each = 12),
    trial_id = rep("t1", 24),
    frame = rep(seq_len(12), 2),
    x = c(seq(150, 240, length.out = 12), seq(170, 260, length.out = 12)),
    y = c(seq(120, 200, length.out = 12), seq(100, 220, length.out = 12)),
    stringsAsFactors = FALSE
  )

  out <- tempfile(fileext = ".png")
  f <- tempfile(fileext = ".csv")
  on.exit(unlink(c(out, f), force = TRUE), add = TRUE)
  utils::write.csv(dat, f, row.names = FALSE)

  p <- plot_watermaze(f, cfg = list(style_mode = "builtin", plot_mode = "line_gradient", out_file = out))
  expect_s3_class(p, "ggplot")
  expect_true(file.exists(out))
})
