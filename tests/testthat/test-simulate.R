test_that("pb_simulate() returns a well-formed pb_boot object", {
  res <- boot_binomial(n = 5)

  expect_s3_class(res, "pb_boot")
  expect_length(res$replicates, 5)
  expect_s3_class(res$replicates[[1]], "glm")
  expect_equal(dim(res$estimates), c(5L, 2L))
  expect_equal(dim(res$std_errors), c(5L, 2L))
  expect_equal(colnames(res$estimates), c("(Intercept)", "mpg"))
  expect_false(anyNA(res$estimates))
  expect_equal(res$n, 5L)
  expect_false(any(res$failed))
})

test_that("replicates differ from each other and from the original fit", {
  res <- boot_binomial(n = 5)
  expect_gt(stats::sd(res$estimates[, "mpg"]), 0)
  expect_false(any(res$estimates[, "mpg"] == stats::coef(res$original)["mpg"]))
})

test_that("`seed` makes results reproducible without touching the global RNG", {
  fit <- fit_gaussian()
  expect_equal(
    pb_simulate(fit, n = 5, seed = 10)$estimates,
    pb_simulate(fit, n = 5, seed = 10)$estimates
  )
  expect_false(isTRUE(all.equal(
    pb_simulate(fit, n = 5, seed = 10)$estimates,
    pb_simulate(fit, n = 5, seed = 11)$estimates
  )))

  set.seed(42)
  expected <- stats::runif(1)
  set.seed(42)
  pb_simulate(fit, n = 3, seed = 10)
  expect_equal(stats::runif(1), expected)
})

test_that("`keep_fits = FALSE` drops the refitted models but keeps estimates", {
  res <- pb_simulate(fit_gaussian(), n = 5, seed = 1, keep_fits = FALSE)
  expect_null(res$replicates)
  expect_equal(dim(res$estimates), c(5L, 3L))
  expect_error(pb_predict_boot(res), "keep_fits")
})

test_that("bootstrap standard errors agree with theory for a linear model", {
  fit <- fit_gaussian()
  res <- pb_simulate(fit, n = 400, seed = 1, keep_fits = FALSE)
  boot_se <- apply(res$estimates, 2, stats::sd)
  model_se <- sqrt(diag(stats::vcov(fit)))
  expect_equal(unname(boot_se / model_se), rep(1, 3), tolerance = 0.15)
})

test_that("transformed terms, missing values and `subset` are handled", {
  cars <- mtcars
  cars$mpg[3] <- NA
  fit <- stats::glm(
    am ~ log(mpg) + poly(wt, 2),
    data = cars, family = stats::binomial(), subset = cyl != 6
  )
  res <- suppressWarnings(pb_simulate(fit, n = 4, seed = 1))

  expect_equal(colnames(res$estimates), names(stats::coef(fit)))
  expect_equal(stats::nobs(res$replicates[[1]]), stats::nobs(fit))
})

test_that("`y ~ .` formulas do not pick up the original response as a predictor", {
  fit <- stats::lm(mpg ~ ., data = mtcars[, c("mpg", "wt", "hp")])
  res <- pb_simulate(fit, n = 3, seed = 1)
  expect_equal(colnames(res$estimates), c("(Intercept)", "wt", "hp"))
  expect_equal(names(stats::coef(res$replicates[[1]])), c("(Intercept)", "wt", "hp"))
})

test_that("two-column binomial responses, offsets and weights are supported", {
  dose <- data.frame(dead = c(2, 8, 15, 23), alive = c(28, 22, 15, 7), dose = 1:4)
  fit <- stats::glm(cbind(dead, alive) ~ dose, data = dose, family = stats::binomial())
  res <- pb_simulate(fit, n = 4, seed = 1)
  expect_false(anyNA(res$estimates))

  set.seed(1)
  counts <- data.frame(x = stats::rnorm(40), exposure = stats::runif(40, 1, 5))
  counts$y <- stats::rpois(40, counts$exposure * exp(0.3 * counts$x))
  fit <- stats::glm(y ~ x + offset(log(exposure)), data = counts, family = stats::poisson())
  res <- pb_simulate(fit, n = 4, seed = 1)
  expect_false(anyNA(res$estimates))

  cars <- mtcars
  cars$w <- rep(1:2, 16)
  fit <- stats::lm(mpg ~ wt, data = cars, weights = w)
  res <- pb_simulate(fit, n = 4, seed = 1)
  expect_equal(stats::weights(res$replicates[[1]]), stats::weights(fit))
})

test_that("`...` overrides arguments of the original call", {
  res <- suppressWarnings(
    pb_simulate(fit_binomial(), n = 3, seed = 1, control = stats::glm.control(maxit = 1))
  )
  expect_equal(res$replicates[[1]]$iter, 1L)
  expect_true(all(res$warned))
})

test_that("refit warnings are collected into a single warning", {
  expect_warning(
    pb_simulate(fit_binomial(), n = 3, seed = 1, control = stats::glm.control(maxit = 1)),
    "3 of 3 bootstrap refits produced warnings"
  )
})

test_that("failed refits are dropped with a single warning", {
  calls <- 0
  refit <- pb_refit
  local_mocked_bindings(pb_refit = function(...) {
    calls <<- calls + 1
    if (calls %in% c(2, 4)) stop("boom")
    refit(...)
  })

  expect_warning(
    res <- pb_simulate(fit_gaussian(), n = 5, seed = 1),
    "2 of 5 bootstrap refits failed and were dropped. First error: boom",
    fixed = TRUE
  )
  expect_equal(res$failed, c(FALSE, TRUE, FALSE, TRUE, FALSE))
  expect_true(all(is.na(res$estimates[c(2, 4), ])))
  expect_null(res$replicates[[2]])
  expect_length(res$replicates, 5)

  expect_false(anyNA(pb_summary_table(res)))
  expect_equal(unique(pb_tidy(res)$replicate), c(1L, 3L, 5L))
  expect_equal(ncol(pb_predict_boot(res)), 3L)
})

test_that("an error is raised when every refit fails", {
  expect_error(
    pb_simulate(fit_binomial(), n = 4, seed = 1, method = "no-such-method"),
    "All 4 bootstrap refits failed"
  )
})

test_that("invalid inputs give informative errors", {
  fit <- fit_gaussian()
  expect_error(pb_simulate("not a model"), "must be fitted with")
  expect_error(pb_simulate(fit, n = 0), "positive whole number")
  expect_error(pb_simulate(fit, n = 2.5), "positive whole number")
  expect_error(pb_simulate(fit, n = 3, seed = "a"), "`seed`")
  expect_error(pb_simulate(fit, n = 3, keep_fits = NA), "`keep_fits`")

  y <- mtcars$mpg
  x <- mtcars$wt
  expect_error(pb_simulate(stats::lm(y ~ x), n = 3), "`data` argument")
})
