test_that("glmer models track fixed effects and variance components", {
  skip_if_not_installed("lme4")
  fit <- lme4::glmer(
    cbind(incidence, size - incidence) ~ period + (1 | herd),
    data = lme4::cbpp, family = stats::binomial()
  )
  res <- suppressWarnings(pb_simulate(fit, n = 4, seed = 1))
  fixed <- names(lme4::fixef(fit))

  expect_s4_class(res$replicates[[1]], "glmerMod")
  # A binomial GLMM has no residual standard deviation.
  expect_equal(colnames(res$estimates), c(fixed, "sd_(Intercept)|herd"))
  expect_false(anyNA(res$estimates))
  expect_false(anyNA(res$std_errors[, fixed]))
  expect_true(all(is.na(res$std_errors[, "sd_(Intercept)|herd"])))
  expect_equal(
    pb_confint(res)$estimate,
    unname(c(lme4::fixef(fit), attr(lme4::VarCorr(fit)$herd, "stddev")))
  )
  expect_output(print(res), "glmerMod (binomial)", fixed = TRUE)
})

test_that("variance components are named as lme4 names them", {
  skip_if_not_installed("lme4")
  fit <- lme4::lmer(Reaction ~ Days + (Days | Subject), data = lme4::sleepstudy)
  pars <- pb_ran_pars(fit)
  vc <- lme4::VarCorr(fit)$Subject

  expect_named(
    pars,
    c("sd_(Intercept)|Subject", "sd_Days|Subject", "cor_Days.(Intercept)|Subject", "sigma")
  )
  expect_equal(unname(pars[1:2]), unname(attr(vc, "stddev")))
  expect_equal(unname(pars[3]), attr(vc, "correlation")[2, 1])
  expect_equal(unname(pars[4]), stats::sigma(fit))
  # The same names, in a different order, as lme4's own intervals.
  lme4_names <- rownames(stats::confint(fit, method = "Wald", oldNames = FALSE))
  expect_setequal(names(pb_coef(fit)), lme4_names)
})

test_that("replicates are identical to those of lme4::bootMer()", {
  skip_if_not_installed("lme4")
  # bootMer() implements the same algorithm (simulate, then refit), so the same
  # seed must give the same replicates. The extractor below is deliberately
  # independent of the one used by the package.
  fit <- lme4::lmer(Reaction ~ Days + (1 | Subject), data = lme4::sleepstudy)
  extract <- function(m) {
    c(lme4::fixef(m), attr(lme4::VarCorr(m)$Subject, "stddev"), stats::sigma(m))
  }
  reference <- lme4::bootMer(fit, FUN = extract, nsim = 8, seed = 11)
  res <- pb_simulate(fit, n = 8, seed = 11, keep_fits = FALSE)

  expect_equal(colnames(res$estimates), c("(Intercept)", "Days", "sd_(Intercept)|Subject", "sigma"))
  expect_equal(unname(res$estimates), unname(reference$t))
})

test_that("summaries cope with parameters that have no standard error", {
  skip_if_not_installed("lme4")
  fit <- lme4::lmer(Reaction ~ Days + (1 | Subject), data = lme4::sleepstudy)
  res <- pb_simulate(fit, n = 30, seed = 1, keep_fits = FALSE)
  variance <- c("sd_(Intercept)|Subject", "sigma")

  key_stats <- pb_key_stats(res)
  expect_equal(key_stats$term[3:4], variance)
  expect_equal(is.na(key_stats$coverage), c(FALSE, FALSE, TRUE, TRUE))
  expect_false(anyNA(key_stats[c("bias", "std_error", "mse")]))

  for (type in c("percentile", "basic", "normal")) {
    expect_false(anyNA(pb_confint(res, type = type)))
  }
  expect_warning(
    student <- pb_confint(res, type = "student"),
    "parameters without a standard error: sd_(Intercept)|Subject, sigma",
    fixed = TRUE
  )
  expect_equal(is.na(student$lower), c(FALSE, FALSE, TRUE, TRUE))
  expect_equal(is.na(student$upper), c(FALSE, FALSE, TRUE, TRUE))

  expect_equal(unique(pb_tidy(res)$term), colnames(res$estimates))
  expect_no_error(ggplot2::ggplot_build(pb_plot_estimates(res, parameter = variance)))
  expect_no_error(ggplot2::ggplot_build(pb_plot_diagnostics(res, parameter = "sigma")))
})

test_that("lmer models support population-level predictions", {
  skip_if_not_installed("lme4")
  fit <- lme4::lmer(Reaction ~ Days + (1 | Subject), data = lme4::sleepstudy)
  res <- suppressWarnings(pb_simulate(fit, n = 4, seed = 1))

  preds <- pb_predict_boot(res, data.frame(Days = c(0, 5)), re.form = NA)
  expect_equal(dim(preds), c(2L, 4L))
  expect_equal(unname(preds[1, ]), unname(res$estimates[, "(Intercept)"]))
})
