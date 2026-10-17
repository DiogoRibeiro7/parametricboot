test_that("studentised intervals for linear contrasts agree with hand-computed pivots", {
  model <- fit_gaussian()
  statistic <- function(fit) c(contrast = unname(sum(stats::coef(fit)[2:3])))
  statistic_se <- function(fit) {
    V <- stats::vcov(fit)
    w <- c(0, 1, 1)
    c(contrast = sqrt(unname(drop(crossprod(w, V %*% w)))))
  }
  res <- pb_simulate(model, n = 70, seed = 19, keep_fits = FALSE,
                     statistic = statistic, statistic_se = statistic_se)
  expect_identical(names(res$statistic_se_estimate), "contrast")
  expect_true(all(res$std_errors > 0))
  theta <- unname(statistic(model))
  se0 <- unname(statistic_se(model))
  pivot <- (res$estimates[, 1] - theta) / res$std_errors[, 1]
  q <- unname(stats::quantile(pivot, c(0.05, 0.95)))
  ci <- pb_confint(res, level = 0.9, type = "student")
  expect_equal(c(ci$lower, ci$upper), theta - se0 * rev(q))
  mc <- pb_confint_mc_error(res, level = 0.9, type = "student", mc_level = 0.8)
  expect_equal(c(mc$lower, mc$upper), c(ci$lower, ci$upper))
})

test_that("delta method for a GLM odds ratio supplies valid standard errors", {
  fit <- fit_binomial()
  stat <- function(model) c(odds_ratio = unname(exp(stats::coef(model)[2])))
  se <- function(model) {
    beta <- unname(stats::coef(model)[2])
    c(odds_ratio = exp(beta) * sqrt(unname(stats::vcov(model)[2, 2])))
  }
  res <- suppressWarnings(pb_simulate(fit, n = 30, seed = 7,
                                      statistic = stat, statistic_se = se))
  expect_equal(pb_confint(res, type = "student")$term, "odds_ratio")
  expect_equal(res$statistic_se_estimate, se(fit))
})

test_that("callbacks must supply strictly positive aligned standard errors", {
  fit <- fit_gaussian()
  stat <- function(fit) c(a = unname(stats::coef(fit)[2]))
  expect_error(pb_simulate(fit, n = 2, statistic_se = function(fit) c(a = 1)),
               "requires")
  for (bad in list(
    function(fit) c(wrong = 1),
    function(fit) c(a = 0),
    function(fit) c(a = NA_real_),
    function(fit) c(a = -1),
    function(fit) 1
  )) {
    expect_error(pb_simulate(fit, n = 2, statistic = stat, statistic_se = bad),
                 "strictly positive")
  }
  old <- pb_simulate(fit, n = 3, seed = 1, statistic = stat)
  expect_null(old$statistic_se_estimate)
  expect_error(pb_confint(old, type = "student"), "standard errors")
})

test_that("serial and parallel custom studentised results are identical", {
  skip_on_cran()
  skip_if_not("parametricboot" %in% rownames(utils::installed.packages()))
  fit <- fit_gaussian()
  stat <- function(fit) c(slope = unname(stats::coef(fit)[2]))
  se <- function(fit) c(slope = sqrt(unname(stats::vcov(fit)[2, 2])))
  x <- pb_simulate(fit, n = 8, seed = 17, statistic = stat, statistic_se = se)
  y <- pb_parallel(fit, n = 8, workers = 2, seed = 17,
                   statistic = stat, statistic_se = se)
  expect_equal(x$estimates, y$estimates)
  expect_equal(x$std_errors, y$std_errors)
  expect_equal(x$statistic_se_estimate, y$statistic_se_estimate)
  expect_equal(pb_confint(x, type = "student"), pb_confint(y, type = "student"))
})
