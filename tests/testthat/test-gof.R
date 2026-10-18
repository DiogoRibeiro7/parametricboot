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

test_that("upper and lower tail tests share the identical seeded bootstrap reference", {
  fit <- fit_binomial()
  upper <- pb_gof(fit, n = 29, seed = 14)
  lower <- pb_gof(fit, n = 29, seed = 14, tail = "less")
  expect_identical(upper$tail, "greater")
  expect_identical(lower$tail, "less")
  expect_equal(upper$reference, lower$reference)
  valid <- upper$reference[!upper$failed]
  B <- length(valid)
  expect_equal(upper$p_value,
               (1 + sum(valid >= upper$observed)) / (B + 1))
  expect_equal(lower$p_value,
               (1 + sum(valid <= lower$observed)) / (B + 1))
  expect_error(pb_gof(fit, n = 2, tail = "two.sided"), "should be one of")
})

test_that("Poisson zero-count lower tail matches independent sampling law", {
  dat <- data.frame(y = c(rep(0L, 6), rep(1L, 9), rep(2L, 5)))
  fit <- stats::glm(y ~ 1, data = dat, family = stats::poisson())
  B <- 450L
  lower <- pb_gof(fit, statistic = "zeros", tail = "less",
                  n = B, seed = 24)
  original <- sum(dat$y == 0)
  p_zero <- exp(-mean(dat$y))
  exact_lower <- stats::pbinom(original, size = nrow(dat), prob = p_zero)
  expect_equal(lower$observed, original)
  expect_equal(lower$p_value, exact_lower, tolerance = 0.075)
  expect_false(any(lower$failed))
  # Model refitting cannot change the response's zero count.
  draws <- withr::with_seed(24, stats::simulate(fit, nsim = B))
  direct_counts <- vapply(draws, function(y) sum(y == 0), integer(1))
  expect_equal(lower$reference, as.numeric(direct_counts))
})

test_that("GOF Monte Carlo limits match exact binomial calculations", {
  fit <- fit_binomial()
  check <- pb_gof(fit, n = 19, seed = 6, tail = "less")
  mc <- pb_gof_mc_error(check, level = 0.9)
  k <- sum(check$reference <= check$observed)
  exact <- stats::binom.test(k, 19, conf.level = 0.9)$conf.int
  expect_identical(mc$tail, "less")
  expect_equal(mc$p_value, check$p_value)
  expect_equal(mc$tail_probability, k / 19)
  expect_equal(mc$mc_standard_error, sqrt((k / 19) * (1 - k / 19) / 19))
  expect_equal(c(mc$lower, mc$upper), as.numeric(exact))
  expect_identical(mc$valid_replicates, 19L)
  expect_identical(mc$failed_replicates, 0L)
  expect_error(pb_gof_mc_error(check, level = 1), "`level`")
  expect_error(pb_gof_mc_error(list()), "pb_gof")
})

test_that("zero tail exceedances still have a positive exact uncertainty bound", {
  check <- pb_gof(fit_binomial(), n = 10, seed = 1)
  check$observed <- max(check$reference) + 1
  check$failed[c(1L, 3L)] <- TRUE
  check$reference[c(1L, 3L)] <- NA_real_
  mc <- pb_gof_mc_error(check)
  expect_identical(mc$exceedances, 0L)
  expect_identical(mc$valid_replicates, 8L)
  expect_identical(mc$failed_replicates, 2L)
  expect_equal(mc$p_value, 1 / 9)
  expect_equal(mc$mc_standard_error, 0)
  expect_gt(mc$upper, 0)
  legacy <- check
  legacy$tail <- NULL
  expect_identical(pb_gof_mc_error(legacy)$tail, "greater")
})

test_that("reference plots build for continuous and discrete statistics", {
  fit <- fit_binomial()
  check <- pb_gof(fit, n = 19, seed = 12)
  p <- pb_plot_gof(check, bins = 12)
  expect_s3_class(p, "ggplot")
  expect_no_error(ggplot2::ggplot_build(p))
  expect_error(pb_plot_gof(check, bins = 0), "`bins`")
  dat <- data.frame(y = c(0L, 1L, 2L, 0L, 1L, 0L, 2L, 1L,
                          0L, 1L, 2L, 1L))
  fit_p <- stats::glm(y ~ 1, data = dat, family = stats::poisson())
  discrete <- pb_gof(fit_p, n = 20, seed = 2, statistic = "zeros")
  expect_no_error(ggplot2::ggplot_build(pb_plot_gof(discrete)))
})
