test_that("pb_predict alias preserves Gaussian predictions", {
  fit <- fit_gaussian()
  boot <- pb_simulate(fit, n = 8, seed = 23)
  data <- mtcars[1:3, c("wt", "hp")]
  expect_identical(pb_predict(boot, data), pb_predict_boot(boot, data))
  expect_identical(pb_predict(boot), pb_predict_boot(boot))
})

test_that("pb_predict alias preserves GLM response scale", {
  fit <- fit_binomial()
  boot <- pb_simulate(fit, n = 8, seed = 24)
  data <- data.frame(mpg = c(12, 20, 28))
  expect_identical(pb_predict(boot, data, type = "response"),
                   pb_predict_boot(boot, data, type = "response"))
})

test_that("pb_predict alias follows strict cached predictions contract", {
  fit <- fit_gaussian()
  data <- mtcars[1:2, c("wt", "hp")]
  boot <- pb_simulate(fit, n = 8, seed = 25, keep_fits = FALSE,
                      newdata = data)
  expect_identical(pb_predict(boot), pb_predict_boot(boot))
  expect_identical(pb_predict(boot, data), pb_predict_boot(boot, data))
  expect_error(pb_predict(boot, mtcars[3:4, c("wt", "hp")]),
               "Stored predictions")
})
