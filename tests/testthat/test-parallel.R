test_that("pb_parallel() reproduces pb_simulate() for the same seed", {
  skip_on_cran()
  # Workers are fresh R sessions, so the package has to be installed.
  skip_if_not("parametricboot" %in% rownames(utils::installed.packages()))

  fit <- fit_gaussian()
  par <- pb_parallel(fit, n = 6, workers = 2, seed = 1)
  seq <- pb_simulate(fit, n = 6, seed = 1)

  expect_s3_class(par, "pb_boot")
  expect_length(par$replicates, 6)
  expect_equal(par$estimates, seq$estimates)
  expect_equal(par$std_errors, seq$std_errors)
})

test_that("pb_parallel() validates `workers`", {
  expect_error(pb_parallel(fit_gaussian(), n = 3, workers = 0), "`workers`")
})
