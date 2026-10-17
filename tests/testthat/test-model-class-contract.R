test_that("canonical base-R lm and glm fits retain their bootstrap support", {
  linear <- fit_gaussian()
  logistic <- fit_binomial()
  expect_identical(class(linear), "lm")
  expect_identical(class(logistic), c("glm", "lm"))
  expect_identical(pb_model_type(linear), "lm")
  expect_identical(pb_model_type(logistic), "lm")
  expect_equal(pb_simulate(linear, n = 3, seed = 5, keep_fits = FALSE)$n, 3)
  expect_equal(pb_simulate(logistic, n = 3, seed = 5, keep_fits = FALSE)$n, 3)
})

test_that("unvalidated lm and glm subclasses refuse bootstrap inference", {
  fit <- fit_binomial()
  for (subclass in c("negbin", "gam", "svyglm")) {
    unvalidated <- fit
    class(unvalidated) <- c(subclass, "glm", "lm")
    err <- tryCatch(pb_simulate(unvalidated, n = 2), error = identity)
    expect_s3_class(err, "parametricboot_validation_error")
    expect_s3_class(err, "dataexcept_validation_error")
    expect_match(conditionMessage(err), "Unsupported lm/glm subclass", fixed = TRUE)
    expect_match(conditionMessage(err), subclass, fixed = TRUE)
    expect_false(dataexcept::is_retryable(err))
  }

  analysis_of_variance <- stats::aov(mpg ~ wt, data = mtcars)
  expect_error(pb_simulate(analysis_of_variance, n = 2),
               "Unsupported lm/glm subclass")
})

test_that("serial, parallel and LRT entry points share the class guard", {
  validated <- fit_gaussian()
  unvalidated <- validated
  class(unvalidated) <- c("aov", "lm")

  expect_error(pb_parallel(unvalidated, n = 2, workers = 2),
               "Unsupported lm/glm subclass")
  expect_error(pb_lrt(validated, unvalidated, n = 2),
               "Unsupported lm/glm subclass")
  expect_error(pb_compare_models(list(unvalidated), n = 2),
               "Unsupported lm/glm subclass")
})

test_that("quasi-likelihood GLMs are rejected before simulating data", {
  quasi <- stats::glm(vs ~ mpg, data = mtcars,
                      family = stats::quasibinomial())
  err <- tryCatch(pb_simulate(quasi, n = 2), error = identity)
  expect_s3_class(err, "parametricboot_validation_error")
  expect_match(conditionMessage(err), "Quasi-likelihood", fixed = TRUE)
  expect_match(conditionMessage(err), "log-likelihood", fixed = TRUE)
  expect_false(dataexcept::is_retryable(err))
  expect_error(pb_lrt(fit_binomial(), quasi, n = 2), "Quasi-likelihood")
})
