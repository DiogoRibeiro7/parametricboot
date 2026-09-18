test_that("print() describes the bootstrap", {
  res <- boot_binomial(n = 5)
  expect_output(print(res), "<pb_boot> Parametric bootstrap")
  expect_output(print(res), "glm (binomial)", fixed = TRUE)
  expect_output(print(res), "(Intercept), mpg", fixed = TRUE)
  utils::capture.output(printed <- withVisible(print(res)))
  expect_false(printed$visible)
  expect_identical(printed$value, res)

  slim <- pb_simulate(fit_gaussian(), n = 3, seed = 1, keep_fits = FALSE)
  expect_output(print(slim), "keep_fits = FALSE", fixed = TRUE)
})

test_that("summary() is pb_summary_table()", {
  res <- boot_binomial(n = 20)
  expect_equal(summary(res), pb_summary_table(res))
  expect_equal(summary(res, level = 0.8), pb_summary_table(res, level = 0.8))
})

test_that("confint() follows the stats::confint() layout", {
  res <- boot_binomial(n = 20)
  ci <- confint(res, level = 0.9)
  expect_true(is.matrix(ci))
  expect_equal(dimnames(ci), list(c("(Intercept)", "mpg"), c("5 %", "95 %")))
  expect_equal(unname(ci[, 1]), pb_confint(res, level = 0.9)$lower)

  expect_equal(rownames(confint(res, parm = "mpg")), "mpg")
  expect_error(confint(res, parm = "nope"), "Unknown parameter")
})
