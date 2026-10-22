# Contract tests for pb_lrt printing use a deterministic small nested model.
# Numerical values are checked against the returned object, not fixed
# platform-dependent printed floating-point digits.

test_that("likelihood-ratio print shows models, replicate count and labels", {
  null <- stats::lm(mpg ~ wt + hp, data = mtcars)
  alternative <- stats::update(null, . ~ . + drat)
  result <- pb_lrt(null, alternative, n = 8, seed = 19)

  rendered <- utils::capture.output(returned <- withVisible(print(result)))
  expect_identical(rendered[1L],
                   "<pb_lrt> Parametric bootstrap likelihood-ratio test")
  expect_identical(rendered[2L], "  Null:        mpg ~ wt + hp")
  expect_identical(rendered[3L], "  Alternative: mpg ~ wt + hp + drat")
  expect_identical(rendered[4L], "  Replicates:  8")
  expect_match(rendered[5L], " on 1 df", fixed = TRUE)
  expect_true(any(grepl("Chi-squared (asymptotic)", rendered, fixed = TRUE)))
  expect_true(any(grepl("Bartlett-corrected", rendered, fixed = TRUE)))
  expect_true(any(grepl("Parametric bootstrap", rendered[-1L], fixed = TRUE)))
  expect_false(returned$visible)
  expect_identical(returned$value, result)
})

test_that("likelihood-ratio printer reports excluded replicates", {
  null <- stats::lm(mpg ~ wt + hp, data = mtcars)
  alternative <- stats::update(null, . ~ . + drat)
  result <- pb_lrt(null, alternative, n = 8, seed = 19)
  result$failed[c(2L, 5L)] <- TRUE
  rendered <- utils::capture.output(print(result))
  expect_identical(rendered[4L], "  Replicates:  8 (2 dropped)")
})

test_that("bootstrap p-value remains a numeric estimate in printed output", {
  null <- stats::lm(mpg ~ wt + hp, data = mtcars)
  alternative <- stats::update(null, . ~ . + drat)
  result <- pb_lrt(null, alternative, n = 8, seed = 19)
  rendered <- utils::capture.output(print(result, digits = 7))
  row <- rendered[grepl("Parametric bootstrap", rendered, fixed = TRUE)]
  # Exclude the heading; only the table row should contain the probability.
  row <- row[!grepl("^<pb_lrt>", row)]
  expect_length(row, 1L)
  expected <- format(result$table$p_value[result$table$test == "bootstrap"],
                     digits = 7)
  expect_true(grepl(expected, row, fixed = TRUE))
})
