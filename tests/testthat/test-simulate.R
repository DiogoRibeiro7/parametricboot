test_that("pb_simulate returns pb_boot", {
  skip_on_cran()
  fit <- stats::glm(vs ~ mpg, data = mtcars, family = binomial())
  res <- pb_simulate(fit, n = 5)
  expect_s3_class(res, "pb_boot")
  expect_length(res$replicates, 5)
})
