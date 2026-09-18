fit_cox <- function() {
  survival::coxph(survival::Surv(time, status) ~ age + sex, data = survival::lung)
}

test_that("coxph models are bootstrapped by model-based resampling", {
  skip_if_not_installed("survival")
  fit <- fit_cox()
  res <- pb_simulate(fit, n = 5, seed = 1)

  expect_s3_class(res$replicates[[1]], "coxph")
  expect_equal(colnames(res$estimates), c("age", "sex"))
  expect_false(anyNA(res$estimates))
  expect_equal(res$replicates[[1]]$n, fit$n)
  expect_equal(dim(pb_predict_boot(res, data.frame(age = 60, sex = 1:2))), c(2L, 5L))
})

test_that("simulated survival data respect the observed design", {
  skip_if_not_installed("survival")
  fit <- fit_cox()
  time <- fit$y[, 1]
  status <- fit$y[, 2]
  sims <- withr::with_seed(1, pb_sim_coxph(fit, 50))

  for (sim in sims[1:5]) {
    expect_equal(dim(sim), c(length(time), 2L))
    expect_true(all(sim[, "status"] %in% c(0, 1)))
    expect_true(all(sim[, "time"] > 0 & sim[, "time"] <= max(time)))
    # Censored subjects keep their censoring time as an upper bound.
    expect_true(all(sim[status == 0, "time"] <= time[status == 0]))
  }
  event_rate <- mean(vapply(sims, function(sim) mean(sim[, "status"]), numeric(1)))
  expect_equal(event_rate, mean(status), tolerance = 0.1)
})

test_that("bootstrap standard errors agree with the partial-likelihood ones", {
  skip_if_not_installed("survival")
  skip_on_cran()
  fit <- fit_cox()
  res <- pb_simulate(fit, n = 200, seed = 1, keep_fits = FALSE)
  ratio <- apply(res$estimates, 2, stats::sd) / sqrt(diag(stats::vcov(fit)))
  expect_equal(unname(ratio), c(1, 1), tolerance = 0.25)
})

test_that("rows dropped for missing values are handled", {
  skip_if_not_installed("survival")
  fit <- survival::coxph(
    survival::Surv(time, status) ~ age + ph.karno,
    data = survival::lung
  )
  expect_lt(fit$n, nrow(survival::lung))
  res <- pb_simulate(fit, n = 3, seed = 1)
  expect_equal(res$replicates[[1]]$n, fit$n)
})

test_that("unsupported coxph features are rejected", {
  skip_if_not_installed("survival")
  lung <- survival::lung
  lung$start <- 0

  stratified <- survival::coxph(
    survival::Surv(time, status) ~ age + survival::strata(sex),
    data = lung
  )
  expect_error(pb_simulate(stratified), "not supported")

  weighted <- survival::coxph(
    survival::Surv(time, status) ~ age,
    data = lung, weights = ph.ecog + 1
  )
  expect_error(pb_simulate(weighted), "Weighted")

  counting <- survival::coxph(survival::Surv(start, time, status) ~ age, data = lung)
  expect_error(pb_simulate(counting), "right-censored")

  no_response <- survival::coxph(survival::Surv(time, status) ~ age, data = lung, y = FALSE)
  expect_error(pb_simulate(no_response), "y = TRUE")
})
