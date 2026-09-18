test_that("pb_compare_models() summarises the metric for each model", {
  fits <- list(
    small = stats::lm(mpg ~ wt, data = mtcars),
    large = stats::lm(mpg ~ wt + hp, data = mtcars)
  )
  out <- pb_compare_models(fits, n = 10, seed = 1)

  expect_named(out, c("model", "observed", "boot_mean", "boot_sd", "lower", "upper"))
  expect_equal(out$model, c("small", "large"))
  expect_equal(out$observed, unname(vapply(fits, stats::AIC, numeric(1))))
  expect_true(all(out$lower <= out$boot_mean & out$boot_mean <= out$upper))
  expect_equal(out, pb_compare_models(fits, n = 10, seed = 1))
})

test_that("unnamed models get default labels and custom metrics work", {
  fits <- list(stats::lm(mpg ~ wt, data = mtcars), b = stats::lm(mpg ~ hp, data = mtcars))
  out <- pb_compare_models(fits, n = 5, metric = stats::deviance, seed = 1)
  expect_equal(out$model, c("model_1", "b"))
  expect_equal(out$observed, unname(vapply(fits, stats::deviance, numeric(1))))
})

test_that("pb_compare_models() validates its inputs", {
  expect_error(pb_compare_models(list()), "non-empty list")
  expect_error(pb_compare_models(fit_gaussian()), "non-empty list")
  expect_error(pb_compare_models(list(fit_gaussian()), metric = "AIC"), "`metric`")
})
