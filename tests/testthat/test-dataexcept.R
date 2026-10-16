test_that("shared argument failures are typed and do not suggest retries", {
  model <- stats::lm(mpg ~ wt, data = mtcars)
  estimates <- matrix(0, nrow = 1L, ncol = 1L,
                      dimnames = list(NULL, "theta"))
  cases <- list(
    list(
      run = function() pb_simulate(model, n = 0),
      message = "`n` must be a single positive whole number."
    ),
    list(
      run = function() pb_simulate(model, n = 2L, seed = "invalid"),
      message = "`seed` must be `NULL` or a single number."
    ),
    list(
      run = function() parametricboot:::pb_check_level(1),
      message = "`level` must be a single number strictly between 0 and 1."
    ),
    list(
      run = function() parametricboot:::pb_check_boot(NULL),
      message = "`results` must be a 'pb_boot' object created by `pb_simulate()` or `pb_parallel()`."
    ),
    list(
      run = function() parametricboot:::pb_check_terms(
        list(estimates = estimates), "absent"
      ),
      message = "Unknown parameter(s): absent. Available: theta."
    )
  )
  for (case in cases) {
    err <- tryCatch(case$run(), error = identity)
    expect_s3_class(err, "parametricboot_validation_error")
    expect_s3_class(err, "dataexcept_validation_error")
    expect_s3_class(err, "dataexcept_error")
    expect_identical(conditionMessage(err), case$message)
    expect_identical(dataexcept::condition_type(err), "ValidationError")
    expect_identical(dataexcept::condition_failure(err)$kind, "permanent")
    expect_false(dataexcept::is_retryable(err))
    expect_true(dataexcept::is_envelope(dataexcept::condition_to_json(err)))
  }
})

test_that("operational error paths retain their previous condition type", {
  err <- tryCatch(parametricboot:::pb_abort("refit failed"), error = identity)
  expect_s3_class(err, "simpleError")
  expect_false(inherits(err, "parametricboot_validation_error"))
})
