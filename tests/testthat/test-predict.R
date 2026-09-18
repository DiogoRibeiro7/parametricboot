test_that("pb_predict_boot() returns one column per replicate", {
  res <- boot_binomial(n = 6)
  new_cars <- data.frame(mpg = c(15, 20, 25))

  preds <- pb_predict_boot(res, new_cars)
  expect_equal(dim(preds), c(3L, 6L))
  expect_equal(
    unname(preds[, 1]),
    unname(stats::predict(res$replicates[[1]], newdata = new_cars))
  )

  fitted_preds <- pb_predict_boot(res)
  expect_equal(dim(fitted_preds), c(nrow(mtcars), 6L))
})

test_that("`...` is passed to predict()", {
  res <- boot_binomial(n = 6)
  probs <- pb_predict_boot(res, data.frame(mpg = c(15, 25)), type = "response")
  expect_true(all(probs > 0 & probs < 1))
})

test_that("a single new observation still gives a matrix", {
  res <- boot_binomial(n = 6)
  expect_equal(dim(pb_predict_boot(res, data.frame(mpg = 20))), c(1L, 6L))
})

test_that("pb_predict_boot() validates `newdata`", {
  res <- boot_binomial(n = 3)
  expect_error(pb_predict_boot(res, newdata = 1:3), "data frame")
})
