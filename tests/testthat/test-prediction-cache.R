test_that("cached predictions match refits and work without stored models", {
  model <- fit_gaussian()
  data <- mtcars[1:4, c("wt", "hp")]
  full <- pb_simulate(model, n = 8, seed = 27, newdata = data,
                      keep_fits = TRUE)
  lean <- pb_simulate(model, n = 8, seed = 27, newdata = data,
                      keep_fits = FALSE)
  expected <- do.call(cbind, lapply(full$replicates, function(fit)
    unname(stats::predict(fit, newdata = data))))
  expect_null(lean$replicates)
  expect_equal(lean$estimates, full$estimates)
  expect_equal(pb_predict_boot(lean), expected)
  expect_equal(pb_predict_boot(lean, newdata = data), expected)
  expect_error(pb_predict_boot(lean, data.frame(wt = 2, hp = 80)),
               "Stored predictions")
  expect_equal(pb_predict_boot(full, data.frame(wt = 2, hp = 80)),
               do.call(cbind, lapply(full$replicates, function(fit)
                 stats::predict(fit, newdata = data.frame(wt = 2, hp = 80)))))
})

test_that("cached predictions preserve argument semantics", {
  fit <- fit_binomial()
  d <- data.frame(mpg = c(15, 20, 25))
  boot <- suppressWarnings(pb_simulate(fit, n = 8, seed = 10,
                      keep_fits = FALSE, newdata = d,
                      predict_args = list(type = "response")))
  actual <- pb_predict_boot(boot, d, type = "response")
  expect_equal(pb_predict_boot(boot), actual)
  expect_true(all(actual >= 0 & actual <= 1))
  expect_error(pb_predict_boot(boot, d), "Stored predictions")
  expect_error(pb_predict_boot(boot, d, type = "link"), "Stored predictions")
  expect_error(pb_simulate(fit, n = 2, predict_args = list(type = "response")),
               "requires")
  expect_error(pb_simulate(fit, n = 2, newdata = d,
                          predict_args = list(newdata = d)), "predict_args")
})

test_that("failed bootstrap refits are not resurrected by the prediction cache", {
  fit <- fit_gaussian()
  d <- mtcars[1:2, c("wt", "hp")]
  boot <- pb_simulate(fit, n = 8, seed = 5, newdata = d,
                      keep_fits = FALSE)
  boot$failed[c(2L, 5L)] <- TRUE
  kept <- pb_predict_boot(boot)
  expect_equal(dim(kept), c(2L, 6L))
  expect_equal(kept, boot$predictions[, -c(2L, 5L), drop = FALSE])
  expect_true(all(is.na(boot$predictions[, boot$prediction_failed,
                                       drop = FALSE])))
})

test_that("cached predictions are reproducible in parallel", {
  skip_on_cran()
  skip_if_not("parametricboot" %in% rownames(utils::installed.packages()))
  fit <- fit_gaussian()
  d <- mtcars[1:3, c("wt", "hp")]
  serial <- pb_simulate(fit, n = 8, seed = 21, newdata = d,
                        keep_fits = FALSE)
  parallel <- pb_parallel(fit, n = 8, workers = 2, seed = 21,
                          newdata = d, keep_fits = FALSE)
  expect_equal(serial$estimates, parallel$estimates)
  expect_equal(pb_predict_boot(serial), pb_predict_boot(parallel))
})
