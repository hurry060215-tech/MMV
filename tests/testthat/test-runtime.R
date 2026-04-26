test_that("load_visual_runtime extracts functions with original environment", {
  rt <- load_visual_runtime(
    style_pkg = "stats",
    function_map = list(stats = c("median")),
    attach_packages = FALSE
  )

  expect_true("stats" %in% rt$packages_loaded)
  expect_true("stats::median" %in% names(rt$extracted_functions))
  fn <- rt$extracted_functions[["stats::median"]]
  expect_type(fn, "closure")
  expect_equal(fn(c(1, 2, 3)), 2)
})
