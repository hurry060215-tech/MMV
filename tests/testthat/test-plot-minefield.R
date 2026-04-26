test_that("plot_minefield works and saves output", {
  dat <- data.frame(
    subject_id = rep(c("m1", "m2"), each = 14),
    group = rep(c("Control", "Model"), each = 14),
    trial_id = rep("t1", 28),
    frame = rep(seq_len(14), 2),
    x = c(seq(10, 45, length.out = 14), seq(12, 48, length.out = 14)),
    y = c(seq(35, 15, length.out = 14), seq(10, 34, length.out = 14)),
    stringsAsFactors = FALSE
  )

  out <- tempfile(fileext = ".png")
  f <- tempfile(fileext = ".csv")
  on.exit(unlink(c(out, f), force = TRUE), add = TRUE)
  utils::write.csv(dat, f, row.names = FALSE)

  p <- plot_minefield(f, cfg = list(style_mode = "builtin", overlay_trajectory = TRUE, out_file = out))
  expect_s3_class(p, "ggplot")
  expect_true(file.exists(out))
})
