test_that("retained-refit predictions remain identical to independent predict calls", {
  fit <- fit_gaussian()
  boot <- pb_simulate(fit, n = 8, seed = 41)
  dat <- mtcars[1:3, c("wt", "hp")]
  expected <- do.call(cbind, lapply(boot$replicates[!boot$failed],
    function(refit) unname(stats::predict(refit, newdata = dat))))
  colnames(expected) <- NULL
  expect_equal(pb_predict(boot, dat), expected)
})

test_that("matrix-valued predictions fail instead of being flattened", {
  fit <- fit_gaussian()
  boot <- pb_simulate(fit, n = 5, seed = 4)
  dat <- mtcars[1:2, c("wt", "hp")]
  expect_error(pb_predict(boot, dat, interval = "confidence"),
               "finite numeric vector")
  expect_error(pb_predict_boot(boot, dat, type = "terms"),
               "finite numeric vector")
})

test_that("nonfinite predictions fail explicitly", {
  fit <- fit_gaussian()
  boot <- pb_simulate(fit, n = 5, seed = 5)
  dat <- data.frame(wt = Inf, hp = 100)
  expect_error(pb_predict(boot, dat), "finite numeric vector")
})
