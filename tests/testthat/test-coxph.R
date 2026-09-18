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

  interaction <- survival::coxph(
    survival::Surv(time, status) ~ age * survival::strata(sex),
    data = lung
  )
  expect_error(pb_simulate(interaction), "strata-by-covariate interactions")

  clustered <- survival::coxph(survival::Surv(time, status) ~ age, data = lung, cluster = inst)
  expect_error(pb_simulate(clustered), "cluster")
  clustered <- survival::coxph(
    survival::Surv(time, status) ~ age + cluster(inst),
    data = lung
  )
  expect_error(pb_simulate(clustered), "cluster")

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

fit_cox_strata <- function() {
  survival::coxph(
    survival::Surv(time, status) ~ age + ph.ecog + survival::strata(sex),
    data = survival::lung
  )
}

test_that("stratified coxph models are bootstrapped within strata", {
  skip_if_not_installed("survival")
  fit <- fit_cox_strata()
  res <- pb_simulate(fit, n = 4, seed = 1)

  expect_equal(colnames(res$estimates), c("age", "ph.ecog"))
  expect_false(anyNA(res$estimates))
  expect_false(any(res$failed))
  expect_equal(res$replicates[[1]]$n, fit$n)
  # The refits are stratified too.
  expect_length(attr(res$replicates[[1]]$terms, "specials")$strata, 1)
})

test_that("strata are recovered with the labels of the baseline hazards", {
  skip_if_not_installed("survival")
  lung <- survival::lung
  expect_null(pb_coxph_strata(fit_cox()))

  fit <- fit_cox_strata()
  strata <- pb_coxph_strata(fit)
  expect_length(strata, fit$n)
  expect_equal(levels(strata), c("sex=1", "sex=2"))
  expect_equal(unname(table(strata)), unname(table(lung$sex[-fit$na.action])), ignore_attr = TRUE)

  formulas <- list(
    survival::Surv(time, status) ~ age + survival::strata(sex, ph.ecog),
    survival::Surv(time, status) ~ age + survival::strata(sex) + survival::strata(ph.ecog)
  )
  for (formula in formulas) {
    fit <- survival::coxph(formula, data = lung)
    base <- survival::basehaz(fit, centered = TRUE)
    expect_true(all(levels(pb_coxph_strata(fit)) %in% levels(base$strata)))
    expect_false(anyNA(pb_simulate(fit, n = 2, seed = 1)$estimates))
  }
})

test_that("the fitted cumulative hazard is the stratum baseline times the relative risk", {
  skip_if_not_installed("survival")
  # The identity that the simulation of failure times relies on, checked
  # against the survival curves computed by the 'survival' package itself.
  fit <- fit_cox_strata()
  strata <- pb_coxph_strata(fit)
  base <- survival::basehaz(fit, centered = TRUE)
  used <- survival::lung[-fit$na.action, ]

  for (i in c(1, 60, 200)) {
    curve <- survival::survfit(fit, newdata = used[i, ])
    stratum <- base[base$strata == as.character(strata[i]), ]
    reference <- stats::approx(
      curve$time, curve$cumhaz,
      xout = stratum$time, method = "constant", rule = 2, f = 0
    )$y
    expect_equal(stratum$hazard * exp(fit$linear.predictors[i]), reference)
  }
})

test_that("simulated data respect the design of each stratum", {
  skip_if_not_installed("survival")
  fit <- fit_cox_strata()
  strata <- pb_coxph_strata(fit)
  time <- fit$y[, 1]
  status <- fit$y[, 2]
  sims <- withr::with_seed(1, pb_sim_coxph(fit, 60))

  for (s in levels(strata)) {
    rows <- strata == s
    for (sim in sims[1:5]) {
      # Follow-up ends when it ended in that stratum, not in the whole study.
      expect_true(all(sim[rows, "time"] <= max(time[rows])))
      expect_true(all(sim[rows & status == 0, "time"] <= time[rows & status == 0]))
    }
    event_rate <- mean(vapply(sims, function(sim) mean(sim[rows, "status"]), numeric(1)))
    expect_equal(event_rate, mean(status[rows]), tolerance = 0.1)
  }
  # The strata differ, so this would fail if they were pooled.
  expect_gt(max(time[strata == "sex=1"]), max(time[strata == "sex=2"]))
})

test_that("stratified bootstrap standard errors agree with the partial-likelihood ones", {
  skip_if_not_installed("survival")
  skip_on_cran()
  fit <- fit_cox_strata()
  res <- pb_simulate(fit, n = 200, seed = 1, keep_fits = FALSE)
  ratio <- apply(res$estimates, 2, stats::sd) / sqrt(diag(stats::vcov(fit)))
  expect_equal(unname(ratio), c(1, 1), tolerance = 0.25)
})

test_that("a robust variance without clustering is still accepted", {
  skip_if_not_installed("survival")
  fit <- survival::coxph(
    survival::Surv(time, status) ~ age,
    data = survival::lung, robust = TRUE
  )
  expect_s3_class(pb_simulate(fit, n = 2, seed = 1), "pb_boot")
})
