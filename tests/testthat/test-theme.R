test_that("theme_mmviz returns a valid theme bundle", {
  th <- theme_mmviz(mode = "builtin")
  expect_type(th, "list")
  expect_true(all(c("mode", "palette", "gg_theme") %in% names(th)))
  expect_true(inherits(th$gg_theme, "theme"))
})
