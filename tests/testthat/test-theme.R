test_that("theme_mmviz returns a valid theme bundle", {
  th <- theme_mmviz(mode = "builtin")
  expect_type(th, "list")
  expect_true(all(c("mode", "palette", "gg_theme") %in% names(th)))
  expect_true(inherits(th$gg_theme, "theme"))
})

test_that("thisplot mode gracefully resolves to an available theme", {
  th <- theme_mmviz(mode = "thisplot")
  expect_true(th$mode %in% c("thisplot", "builtin"))
  expect_true(inherits(th$gg_theme, "theme"))
  expect_gte(length(th$palette$line_gradient), 3L)
})
