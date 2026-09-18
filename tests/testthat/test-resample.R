test_that("pb_resample() draws rows with replacement", {
  cars <- mtcars
  cars$id <- seq_len(nrow(cars))

  set.seed(1)
  out <- pb_resample(cars)
  expect_equal(dim(out), dim(cars))
  expect_named(out, names(cars))
  expect_true(all(out$id %in% cars$id))
  expect_lt(length(unique(out$id)), nrow(cars))

  expect_equal(nrow(pb_resample(cars, size = 100)), 100L)
  expect_equal(nrow(pb_resample(cars, size = 1)), 1L)
})

test_that("pb_resample() validates its inputs", {
  expect_error(pb_resample(1:10), "data frame")
  expect_error(pb_resample(mtcars[0, ]), "at least one row")
  expect_error(pb_resample(mtcars, size = 0), "positive whole number")
})
