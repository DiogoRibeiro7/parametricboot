test_that("glmer models are bootstrapped on their fixed effects", {
  skip_if_not_installed("lme4")
  fit <- lme4::glmer(
    cbind(incidence, size - incidence) ~ period + (1 | herd),
    data = lme4::cbpp, family = stats::binomial()
  )
  res <- suppressWarnings(pb_simulate(fit, n = 4, seed = 1))

  expect_s4_class(res$replicates[[1]], "glmerMod")
  expect_equal(colnames(res$estimates), names(lme4::fixef(fit)))
  expect_false(anyNA(res$estimates))
  expect_false(anyNA(res$std_errors))
  expect_equal(pb_confint(res)$estimate, unname(lme4::fixef(fit)))
  expect_output(print(res), "glmerMod (binomial)", fixed = TRUE)
})

test_that("lmer models are supported, including population-level predictions", {
  skip_if_not_installed("lme4")
  fit <- lme4::lmer(Reaction ~ Days + (1 | Subject), data = lme4::sleepstudy)
  res <- suppressWarnings(pb_simulate(fit, n = 4, seed = 1))

  expect_equal(colnames(res$estimates), c("(Intercept)", "Days"))
  preds <- pb_predict_boot(res, data.frame(Days = c(0, 5)), re.form = NA)
  expect_equal(dim(preds), c(2L, 4L))
  expect_equal(unname(preds[1, ]), unname(res$estimates[, "(Intercept)"]))
})
