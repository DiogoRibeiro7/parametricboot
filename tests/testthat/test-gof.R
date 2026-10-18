test_that("parametric GOF matches independently recomputed deviance refits", {
  fit <- stats::glm(vs ~ mpg, data = mtcars, family = stats::binomial())
  draws <- withr::with_seed(23, stats::simulate(fit, nsim = 12))
  test <- pb_gof(fit, n = 12, seed = 23)
  expect_s3_class(test, "pb_gof")
  expect_equal(test$observed, stats::deviance(fit))
  manual <- vapply(draws, function(y) {
    dat <- mtcars
    dat$vs <- y
    stats::deviance(stats::glm(vs ~ mpg, data = dat,
                               family = stats::binomial()))
  }, numeric(1))
  expect_equal(test$reference, unname(manual), tolerance = 1e-7)
  expect_equal(test$p_value,
               (1 + sum(manual >= test$observed)) / 13)
})

test_that("Pearson and zero checks use the correct observed statistics", {
  fit <- stats::glm(am ~ mpg, data = mtcars, family = stats::binomial())
  pearson <- pb_gof(fit, statistic = "pearson", n = 10, seed = 4)
  expect_equal(pearson$observed,
               sum(stats::residuals(fit, type = "pearson")^2))
  counts <- data.frame(x = rep(0:5, each = 8))
  counts$y <- c(rep(0, 6), rep(1, 42))
  pois <- stats::glm(y ~ x, family = stats::poisson(), data = counts)
  zeros <- pb_gof(pois, statistic = "zeros", n = 12, seed = 2)
  expect_equal(zeros$observed, sum(counts$y == 0))
  expect_true(all(zeros$reference >= 0))
})

test_that("GOF rejects unsupported models and preserves RNG", {
  expect_error(pb_gof(fit_gaussian(), n = 2), "GLM")
  fit <- fit_binomial()
  expect_error(pb_gof(fit, n = 2, statistic = "zeros"), "count")
  expect_error(pb_gof(fit, n = 0), "positive whole")
  set.seed(71)
  expected <- stats::runif(1)
  set.seed(71)
  pb_gof(fit, n = 3, seed = 8)
  expect_equal(stats::runif(1), expected)
})
