# Statistical contracts for diagnostic and prediction plots.
# Compare against independent base-R calculations, not pixel snapshots.

test_that("diagnostic running means and reference markers match coefficients", {
  fit <- fit_gaussian()
  boot <- pb_simulate(fit, n = 18, seed = 33)
  plot <- pb_plot_diagnostics(boot, parameter = "wt")
  built <- ggplot2::ggplot_build(plot)

  values <- boot$estimates[!boot$failed, "wt"]
  expect_equal(plot$data$running_mean,
               unname(cumsum(values) / seq_along(values)))
  expect_equal(as.numeric(plot$data$replicate), which(!boot$failed))
  expect_equal(unique(built$data[[2]]$yintercept),
               unname(stats::coef(fit)["wt"]))
  expect_s3_class(plot$layers[[3]]$geom, "GeomLine")
  expect_no_error(ggplot2::ggplot_build(plot))
})

test_that("numeric prediction ribbons use independent percentile calculations", {
  fit <- fit_gaussian()
  boot <- pb_simulate(fit, n = 18, seed = 34)
  dat <- data.frame(wt = c(2, 2.6, 3.2), hp = c(100, 120, 140))
  graph <- pb_plot_predictions(boot, dat, x = "wt", level = 0.8)
  draws <- vapply(boot$replicates[!boot$failed], function(refit) {
    as.numeric(stats::predict(refit, newdata = dat))
  }, numeric(nrow(dat)))
  expected <- t(apply(draws, 1L, stats::quantile,
                      probs = c(0.1, 0.9), names = FALSE))
  expect_equal(graph$data$lower, unname(expected[, 1L]))
  expect_equal(graph$data$upper, unname(expected[, 2L]))
  expect_equal(graph$data$prediction,
               unname(as.numeric(stats::predict(fit, newdata = dat))))
  expect_equal(graph$data$x, dat$wt)
  expect_s3_class(graph$layers[[1]]$geom, "GeomRibbon")
  expect_no_error(ggplot2::ggplot_build(graph))
})

test_that("categorical prediction plots retain row correspondence", {
  fit <- fit_gaussian()
  boot <- pb_simulate(fit, n = 12, seed = 35)
  dat <- data.frame(wt = c(2.4, 3.1), hp = c(95, 145),
                    category = c("low", "high"))
  graph <- pb_plot_predictions(boot, dat, x = "category", level = 0.9)
  expect_identical(as.character(graph$data$x), dat$category)
  expect_equal(graph$data$prediction,
               unname(as.numeric(stats::predict(fit, newdata = dat))))
  expect_true(all(graph$data$lower <= graph$data$upper))
  expect_s3_class(graph$layers[[1]]$geom, "GeomPointrange")
  expect_no_error(ggplot2::ggplot_build(graph))
})
