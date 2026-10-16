test_that("Monte Carlo precision for bias agrees with independent formulas", {
  fit <- fit_gaussian()
  res <- pb_simulate(fit, n = 30, seed = 19, keep_fits = FALSE)
  mc <- pb_mc_error(res)
  stats <- pb_key_stats(res)
  expect_identical(mc$term, stats$term)
  expect_identical(mc$replicates, rep(30L, length(stats$term)))
  expect_equal(mc$bias, stats$bias)
  expect_equal(mc$std_error, stats$std_error)
  expect_equal(mc$bias_mc_se, stats$std_error / sqrt(30))
  for (j in seq_along(stats$term)) {
    x <- res$estimates[, j]
    s <- stats::sd(x)
    fourth <- stats::sd(((x - mean(x)) / s)^2)
    expect_equal(mc$std_error_mc_se[j], s * fourth / (2 * sqrt(30)))
  }
  set.seed(23)
  before <- .Random.seed
  pb_mc_error(res)
  expect_identical(.Random.seed, before)
})

test_that("Monte Carlo precision excludes failed and missing replicates", {
  res <- pb_simulate(fit_gaussian(), n = 12, seed = 14, keep_fits = FALSE)
  res$failed[c(1L, 2L)] <- TRUE
  res$estimates[c(1L, 2L), ] <- NA_real_
  res$estimates[3L, 2L] <- NA_real_
  mc <- pb_mc_error(res)
  expect_identical(mc$replicates, c(10L, 9L, 10L))
  expect_identical(mc$failed_replicates, rep(2L, 3L))
  expect_equal(mc$bias_mc_se[2L],
               stats::sd(res$estimates[4:12, 2L]) / sqrt(9))
  res$estimates[3:12, 1L] <- 1
  expect_true(is.na(pb_mc_error(res)$std_error_mc_se[1L]))
})

test_that("rank bounds match binomial quantiles without simulation", {
  x <- seq_len(40)
  q <- 0.25
  conf <- 0.8
  result <- parametricboot:::.pb_mc_rank_bounds(x, q, conf)
  low <- stats::qbinom(0.1, 40, q)
  high <- stats::qbinom(0.9, 40, q) + 1
  expect_equal(result, c(x[low], x[high]))
  # Too few replicates for an extreme tail should yield unbounded limits.
  expect_identical(parametricboot:::.pb_mc_rank_bounds(1:10, 0.025, 0.95)[1L],
                   -Inf)
  expect_identical(parametricboot:::.pb_mc_rank_bounds(1:10, 0.975, 0.95)[2L],
                   Inf)
})

test_that("interval Monte Carlo bounds preserve current limits and transform correctly", {
  res <- pb_simulate(fit_gaussian(), n = 40, seed = 9, keep_fits = FALSE)
  pct <- pb_confint_mc_error(res, level = 0.5, mc_level = 0.8)
  basic <- pb_confint_mc_error(res, level = 0.5, type = "basic",
                              mc_level = 0.8)
  expect_identical(pct[c("term", "lower", "upper")],
                   pb_confint(res, level = 0.5)[c("term", "lower", "upper")])
  expect_identical(basic[c("term", "lower", "upper")],
                   pb_confint(res, level = 0.5, type = "basic")[
                     c("term", "lower", "upper")])
  theta <- unname(stats::coef(res$original))
  expect_equal(basic$lower_mc_low, 2 * theta - pct$upper_mc_high)
  expect_equal(basic$lower_mc_high, 2 * theta - pct$upper_mc_low)
  expect_equal(basic$upper_mc_low, 2 * theta - pct$lower_mc_high)
  expect_equal(basic$upper_mc_high, 2 * theta - pct$lower_mc_low)
})

test_that("studentised Monte Carlo limits use finite bootstrap pivots", {
  res <- pb_simulate(fit_gaussian(), n = 45, seed = 12, keep_fits = FALSE)
  mc <- pb_confint_mc_error(res, level = 0.8, type = "student",
                            mc_level = 0.8)
  theta <- unname(stats::coef(res$original)[2L])
  original_se <- unname(sqrt(diag(stats::vcov(res$original)))[2L])
  pivots <- (res$estimates[, 2L] - theta) / res$std_errors[, 2L]
  bounds <- parametricboot:::.pb_mc_rank_bounds(pivots, 0.9, 0.8)
  expect_equal(mc$lower_mc_low[2L], theta - original_se * bounds[2L])
  expect_equal(mc$lower_mc_high[2L], theta - original_se * bounds[1L])
  expect_identical(mc[c("term", "lower", "upper")],
                   pb_confint(res, level = 0.8, type = "student")[
                     c("term", "lower", "upper")])
})

test_that("invalid levels and unsupported interval families fail explicitly", {
  res <- pb_simulate(fit_gaussian(), n = 8, seed = 20, keep_fits = FALSE)
  expect_error(pb_confint_mc_error(res, mc_level = 1), "level")
  expect_error(pb_confint_mc_error(res, type = "normal"), "should be one of")
  expect_error(pb_mc_error(list()), "pb_boot")
})
