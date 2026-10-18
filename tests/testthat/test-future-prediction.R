test_that("Gaussian future draws equal independent conditional normal draws", {
  fit <- fit_gaussian()
  boot <- pb_simulate(fit, n = 16, seed = 5, keep_fits = TRUE)
  newdata <- mtcars[1:2, c("wt", "hp")]
  draws <- pb_predict_observations(boot, newdata, seed = 17)
  independent <- withr::with_seed(17, {
    samples <- lapply(boot$replicates, function(refit) {
      stats::rnorm(nrow(newdata),
        mean = as.numeric(stats::predict(refit, newdata = newdata)),
        sd = stats::sigma(refit)
      )
    })
    matrix(as.numeric(unlist(samples, use.names = FALSE)), nrow = 2)
  })
  expect_equal(draws, independent)
  expect_equal(dim(draws), c(2L, 16L))
  interval <- pb_predict_interval(boot, newdata, level = 0.9, seed = 17)
  q <- apply(draws, 1, stats::quantile,
             probs = c(0.05, 0.95), names = FALSE)
  expect_equal(interval$lower, as.numeric(q[1, ]))
  expect_equal(interval$upper, as.numeric(q[2, ]))
  expect_equal(interval$prediction,
               as.numeric(stats::predict(fit, newdata = newdata)))
  expect_identical(interval$successful_replicates, c(16L, 16L))
  expect_equal(dim(pb_predict_observations(
    boot, newdata[1, , drop = FALSE], seed = 17
  )), c(1L, 16L))
})

test_that("Gaussian prediction spread includes residual and parameter uncertainty", {
  fit <- fit_gaussian()
  boot <- pb_simulate(fit, n = 550, seed = 42, keep_fits = TRUE)
  newdata <- mtcars[1, c("wt", "hp"), drop = FALSE]
  mu <- as.numeric(pb_predict_boot(boot, newdata))
  residual_variance <- vapply(boot$replicates,
                             function(refit) stats::sigma(refit)^2,
                             numeric(1))
  expected_variance <- stats::var(mu) + mean(residual_variance)
  future <- pb_predict_observations(boot, newdata, seed = 4)
  expect_lt(abs(stats::var(as.numeric(future)) - expected_variance) /
              expected_variance, 0.20)
  means_ci <- stats::quantile(mu, probs = c(0.025, 0.975),
                               names = FALSE)
  future_ci <- pb_predict_interval(boot, newdata, seed = 4)
  expect_gt(future_ci$upper - future_ci$lower, diff(means_ci))
})

test_that("Poisson future observation mixture has appropriate process variance", {
  dat <- data.frame(x = rep(c(-1, 0, 1), each = 60))
  dat$y <- withr::with_seed(4, stats::rpois(
    nrow(dat), lambda = exp(0.35 + 0.4 * dat$x)
  ))
  fit <- stats::glm(y ~ x, data = dat, family = stats::poisson())
  boot <- pb_simulate(fit, n = 350, seed = 42, keep_fits = TRUE)
  newdata <- data.frame(x = 0)
  draws <- pb_predict_observations(boot, newdata, seed = 29)
  expect_equal(dim(draws), c(1L, 350L))
  expect_true(all(draws >= 0 & draws == floor(draws)))
  mu <- as.numeric(pb_predict_boot(boot, newdata))
  variance_mixture <- mean(mu) + stats::var(mu)
  expect_lt(abs(stats::var(as.numeric(draws)) - variance_mixture) /
              variance_mixture, 0.25)
})

test_that("negative-binomial predictive outcomes use re-estimated dispersion", {
  skip_if_not_installed("MASS")
  dat <- data.frame(x = rep(seq(-1, 1, length.out = 30), 3))
  dat$y <- withr::with_seed(13, stats::rnbinom(
    nrow(dat), mu = exp(0.6 + 0.2 * dat$x), size = 1.3
  ))
  fit <- MASS::glm.nb(y ~ x, data = dat)
  boot <- suppressWarnings(pb_simulate(
    fit, n = 12, seed = 20, keep_fits = TRUE
  ))
  newdata <- data.frame(x = 0)
  draws <- pb_predict_observations(boot, newdata, seed = 3)
  manual <- withr::with_seed(3, {
    samples <- lapply(boot$replicates[!boot$failed], function(refit) {
      stats::rnbinom(1, size = refit$theta,
        mu = as.numeric(stats::predict(refit, newdata = newdata,
                                      type = "response")))
    })
    matrix(as.numeric(unlist(samples, use.names = FALSE)), nrow = 1)
  })
  expect_equal(draws, manual)
  expect_true(all(draws >= 0 & draws == floor(draws)))
})

test_that("future predictive draws fail closed for unsupported assumptions", {
  dat <- mtcars[1:2, c("wt", "hp"), drop = FALSE]
  fit <- fit_gaussian()
  boot <- pb_simulate(fit, n = 5, seed = 1, keep_fits = TRUE)
  expect_error(pb_predict_interval(boot, dat, level = 1), "`level`")
  expect_error(pb_predict_observations(boot, data.frame()), "non-empty")
  expect_error(pb_predict_observations(boot, dat, seed = "bad"), "`seed`")
  lean <- pb_simulate(fit, n = 5, seed = 1, keep_fits = FALSE,
                      newdata = dat)
  expect_error(pb_predict_observations(lean, dat), "keep_fits")
  binomial <- pb_simulate(fit_binomial(), n = 4, seed = 1)
  expect_error(pb_predict_observations(binomial, data.frame(mpg = 19)),
               "Gaussian lm, Poisson glm")
  weights <- rep(c(1, 2), length.out = nrow(mtcars))
  weighted <- stats::lm(mpg ~ wt + hp, data = mtcars, weights = weights)
  wboot <- pb_simulate(weighted, n = 3, seed = 4)
  expect_error(pb_predict_observations(wboot, dat), "non-unit weights")
})

test_that("predictive sampling with seed leaves session RNG untouched", {
  fit <- fit_gaussian()
  boot <- pb_simulate(fit, n = 5, seed = 1)
  dat <- mtcars[1, c("wt", "hp"), drop = FALSE]
  set.seed(87)
  expected <- stats::runif(1)
  set.seed(87)
  pb_predict_interval(boot, dat, seed = 12)
  expect_equal(stats::runif(1), expected)
})
