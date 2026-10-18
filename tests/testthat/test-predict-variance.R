test_that("Gaussian predictive variance obeys total-variance identity", {
  fit <- fit_gaussian()
  boot <- pb_simulate(fit, n = 20, seed = 13, keep_fits = TRUE)
  dat <- mtcars[1:2, c("wt", "hp")]
  v <- pb_predict_variance(boot, dat)
  means <- vapply(boot$replicates[!boot$failed], function(fit) {
    as.numeric(stats::predict(fit, newdata = dat))
  }, numeric(2))
  expected_parameter <- rowMeans((means - rowMeans(means))^2)
  expected_observation <- mean(vapply(
    boot$replicates[!boot$failed], function(fit) stats::sigma(fit)^2,
    numeric(1)
  ))
  expect_equal(v$parameter_variance, expected_parameter)
  expect_equal(v$observation_variance, rep(expected_observation, 2))
  expect_equal(v$total_variance,
               v$parameter_variance + v$observation_variance)
  expect_identical(v$successful_replicates, rep(20L, 2))
})

test_that("Poisson predictive variance uses conditional mean as process variance", {
  dat <- data.frame(x = rep(c(-1, 0, 1), each = 30))
  dat$y <- withr::with_seed(19, stats::rpois(
    nrow(dat), lambda = exp(0.2 + 0.4 * dat$x)
  ))
  fit <- stats::glm(y ~ x, data = dat, family = stats::poisson())
  boot <- pb_simulate(fit, n = 18, seed = 8)
  v <- pb_predict_variance(boot, data.frame(x = 0))
  means <- vapply(boot$replicates[!boot$failed], function(fit) {
    as.numeric(stats::predict(fit, newdata = data.frame(x = 0),
                              type = "response"))
  }, numeric(1))
  expect_equal(v$observation_variance, mean(means))
  expect_equal(v$parameter_variance, mean((means - mean(means))^2))
  expect_equal(v$prediction, as.numeric(stats::predict(
    fit, newdata = data.frame(x = 0), type = "response"
  )))
})

test_that("Negative-binomial variance uses every refit's theta", {
  skip_if_not_installed("MASS")
  dat <- data.frame(x = rep(seq(-1, 1, length.out = 30), 3))
  dat$y <- withr::with_seed(13, stats::rnbinom(
    nrow(dat), mu = exp(0.6 + 0.2 * dat$x), size = 1.3
  ))
  fit <- MASS::glm.nb(y ~ x, data = dat)
  boot <- suppressWarnings(pb_simulate(fit, n = 12, seed = 20))
  v <- pb_predict_variance(boot, data.frame(x = 0))
  expected <- vapply(boot$replicates[!boot$failed], function(refit) {
    mu <- as.numeric(stats::predict(refit, newdata = data.frame(x = 0),
                                     type = "response"))
    mu + mu^2 / refit$theta
  }, numeric(1))
  expect_equal(v$observation_variance, mean(expected))
})

test_that("Predictive variance rejects unsupported or insufficient inputs", {
  dat <- mtcars[1, c("wt", "hp"), drop = FALSE]
  boot <- pb_simulate(fit_gaussian(), n = 5, seed = 1)
  expect_error(pb_predict_variance(boot, data.frame()), "non-empty")
  lean <- pb_simulate(fit_gaussian(), n = 5, seed = 1,
                      keep_fits = FALSE, newdata = dat)
  expect_error(pb_predict_variance(lean, dat), "keep_fits")
  binomial <- pb_simulate(fit_binomial(), n = 4, seed = 1)
  expect_error(pb_predict_variance(binomial, data.frame(mpg = 19)),
               "Gaussian lm, Poisson glm")
})
