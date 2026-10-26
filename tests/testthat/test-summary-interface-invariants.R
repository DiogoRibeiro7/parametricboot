# The convenience summary must be an exact composition of its two
# documented components. These tests constrain API compatibility while the
# interface review remains open.

test_that("summary combines key statistics and interval endpoints exactly", {
  results <- pb_simulate(fit_gaussian(), n = 24, seed = 501,
                         keep_fits = FALSE)
  for (method in c("percentile", "basic", "normal", "student")) {
    keys <- pb_key_stats(results, level = 0.9)
    interval <- pb_confint(results, level = 0.9, type = method)
    actual <- pb_summary_table(results, level = 0.9, type = method)
    expect_identical(names(actual), c(names(keys), "lower", "upper"))
    expect_equal(actual[names(keys)], keys)
    expect_equal(actual[c("lower", "upper")],
                 interval[c("lower", "upper")])
    expect_equal(summary(results, level = 0.9, type = method), actual)
  }
})

test_that("summary excludes failed refits consistently with components", {
  results <- pb_simulate(fit_gaussian(), n = 14, seed = 502,
                         keep_fits = FALSE)
  results$failed[c(2L, 5L)] <- TRUE
  actual <- pb_summary_table(results, type = "percentile")
  expect_equal(actual$boot_mean,
               unname(colMeans(results$estimates[!results$failed, ,
                                                 drop = FALSE])))
  expect_equal(actual$std_error,
               unname(apply(results$estimates[!results$failed, ,
                                             drop = FALSE], 2L, stats::sd)))
  expect_equal(actual[c("lower", "upper")],
               pb_confint(results)[c("lower", "upper")])
})

test_that("summary and component interfaces reject invalid interval levels", {
  results <- pb_simulate(fit_gaussian(), n = 5, seed = 503)
  for (level in c(-0.1, 0, 1, 1.1, NA_real_)) {
    expect_error(pb_summary_table(results, level = level), "`level`")
    expect_error(pb_key_stats(results, level = level), "`level`")
  }
})
