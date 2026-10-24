# Test semantic plot contracts rather than brittle pixel snapshots.
# These checks guard against plots that render but display incorrect values.

test_that("estimate histogram overlays original coefficient positions", {
  fit <- fit_gaussian()
  boot <- pb_simulate(fit, n = 20, seed = 42)
  graph <- pb_plot_estimates(boot, parameter = "wt", bins = 8)
  built <- ggplot2::ggplot_build(graph)

  expect_s3_class(graph$layers[[1]]$geom, "GeomBar")
  expect_s3_class(graph$layers[[2]]$geom, "GeomVline")
  expect_equal(unique(built$data[[2]]$xintercept),
               unname(stats::coef(fit)["wt"]))
  expect_equal(sum(built$data[[1]]$count), sum(!boot$failed))
  expect_identical(graph$labels$title,
                   "Bootstrap distribution of the estimates")
})

test_that("likelihood-ratio plotting matches the reference and chi-squared law", {
  null <- stats::lm(mpg ~ wt + hp, data = mtcars)
  alternative <- stats::update(null, . ~ . + drat)
  result <- pb_lrt(null, alternative, n = 30, seed = 5)
  graph <- pb_plot_lrt(result, bins = 12)
  built <- ggplot2::ggplot_build(graph)

  expect_equal(sum(graph$data$count), sum(!result$failed))
  expect_equal(nrow(graph$data), 12L)
  expect_equal(unique(built$data[[4]]$xintercept),
               result$statistic)
  expect_equal(graph$data$expected,
               sum(!result$failed) * diff(stats::pchisq(
                 seq(0, 1.02 * max(
                   result$reference[!result$failed], result$statistic,
                   stats::qchisq(0.99, result$df)
                 ), length.out = 13L), result$df
               )))
  expect_true(all(graph$data$count >= 0))
  expect_true(all(graph$data$expected >= 0))
})

test_that("filtered estimate plots exclude unselected terms", {
  boot <- pb_simulate(fit_gaussian(), n = 10, seed = 3)
  graph <- pb_plot_estimates(boot, parameter = "hp", bins = 5)
  expect_identical(levels(graph$data$term), "hp")
  expect_true(all(as.character(graph$data$term) == "hp"))
  expect_equal(nrow(graph$data), sum(!boot$failed))
})
