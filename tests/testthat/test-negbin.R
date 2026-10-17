test_that("negative-binomial simulation follows independent mean and variance identities", {
  skip_if_not_installed("MASS")
  counts <- data.frame(x = rep(seq(-1, 1, length.out = 30), 2))
  set.seed(12)
  counts$y <- stats::rnbinom(nrow(counts), mu = exp(0.6 + 0.4 * counts$x),
                             size = 2.5)
  fit <- MASS::glm.nb(y ~ x, data = counts)
  expect_identical(class(fit), c("negbin", "glm", "lm"))
  expect_identical(pb_model_type(fit), "negbin")
  sims <- withr::with_seed(7, stats::simulate(fit, nsim = 300))
  observed <- unlist(sims, use.names = FALSE)
  expect_equal(mean(observed), mean(stats::fitted(fit)), tolerance = 0.2)
  # Compare row-wise simulated moments to theoretical Var(Y)=mu+mu^2/theta.
  mat <- as.matrix(sims)
  target <- stats::fitted(fit) + stats::fitted(fit)^2 / fit$theta
  expect_equal(mean(apply(mat, 1, stats::var)), mean(target), tolerance = 0.45)
})

test_that("bootstrap re-estimates negative-binomial dispersion on refitting", {
  skip_if_not_installed("MASS")
  set.seed(14)
  dat <- data.frame(x = rep(seq(-1, 1, length.out = 30), 3))
  dat$y <- stats::rnbinom(nrow(dat), mu = exp(0.5 + 0.35 * dat$x), size = 2)
  model <- MASS::glm.nb(y ~ x, data = dat)
  samples <- withr::with_seed(21, stats::simulate(model, nsim = 4))
  res <- suppressWarnings(pb_simulate(model, n = 4, seed = 21))
  expect_s3_class(res, "pb_boot")
  expect_false(any(res$failed))
  for (i in seq_len(4)) {
    refit_dat <- dat
    refit_dat$y <- samples[[i]]
    direct <- suppressWarnings(MASS::glm.nb(y ~ x, data = refit_dat))
    expect_equal(unname(stats::coef(res$replicates[[i]])),
                 unname(stats::coef(direct)), tolerance = 1e-5)
    expect_equal(res$replicates[[i]]$theta, direct$theta, tolerance = 1e-5)
  }
})

test_that("negative-binomial class guards reject weights and invalid theta", {
  skip_if_not_installed("MASS")
  set.seed(11)
  dat <- data.frame(x = seq_len(70))
  dat$y <- stats::rnbinom(70, mu = exp(0.2 + 0.006 * dat$x), size = 2)
  fit <- MASS::glm.nb(y ~ x, data = dat)
  bad <- fit
  bad$theta <- -1
  expect_error(pb_simulate(bad, n = 2), "finite positive theta")
  weighted <- fit
  weighted$prior.weights[[1]] <- 2
  expect_error(pb_simulate(weighted, n = 2), "Weighted MASS::glm.nb")
  other <- fit
  class(other) <- c("fake", "negbin", "glm", "lm")
  expect_error(pb_simulate(other, n = 2), "Unsupported lm/glm subclass")
  expect_error(pb_lrt(stats::glm(y ~ x, data = dat, family = stats::poisson()),
                      fit, n = 2), "require two MASS::glm.nb")
})
