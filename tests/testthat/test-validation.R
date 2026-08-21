test_that("plot configuration errors are actionable", {
  dat <- data.frame(
    subject_id = c("s1", "s1"),
    group = c("Sham", "Sham"),
    trial_id = c("t1", "t1"),
    frame = c(1, 2),
    x = c(10, 11),
    y = c(20, 21)
  )

  expect_error(
    plot_watermaze(dat, cfg = list(plot_mode = "typo")),
    "line_gradient, heatmap"
  )
  expect_error(
    plot_watermaze(dat, cfg = list(panel_per_row = 0)),
    "positive number"
  )
})

test_that("data-frame inputs reject missing identifiers", {
  dat <- data.frame(
    subject_id = c("s1", "s1"),
    group = c("", "Sham"),
    trial_id = c("t1", "t1"),
    frame = c(1, 2),
    x = c(10, 11),
    y = c(20, 21)
  )

  expect_error(plot_watermaze(dat), "group.*missing or empty")
})
