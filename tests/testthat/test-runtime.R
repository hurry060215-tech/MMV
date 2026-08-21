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

test_that("python backend remains compatible but is explicitly deprecated", {
  expect_warning(
    state <- use_python_backend(FALSE),
    "deprecated"
  )
  expect_false(state$enable)
  expect_null(state$module)

  expect_warning(
    enabled <- use_python_backend(TRUE, module = "mmviz_backend"),
    "deprecated"
  )
  expect_true(enabled$enable)
  expect_equal(enabled$module, "mmviz_backend")
  expect_warning(use_python_backend(FALSE), "deprecated")
  dat <- data.frame(
    subject_id = "s1", group = "g1", trial_id = "t1", frame = 1,
    x = 1, y = 1, stringsAsFactors = FALSE
  )
  expect_equal(MMV:::.mmviz_apply_python_backend(dat, "watermaze"), dat)
})
