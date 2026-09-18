test_that("pb_drop_warned() excludes replicates that raised warnings", {
  res <- boot_binomial(n = 30)
  res$warned <- seq_len(30) %in% c(2, 5, 17)

  clean <- pb_drop_warned(res)
  expect_s3_class(clean, "pb_boot")
  expect_equal(clean$failed, res$warned)
  expect_equal(clean$warned, res$warned)
  expect_true(all(is.na(clean$estimates[res$warned, ])))
  expect_true(all(is.na(clean$std_errors[res$warned, ])))
  expect_equal(clean$estimates[!res$warned, ], res$estimates[!res$warned, ])
  expect_true(all(vapply(clean$replicates[res$warned], is.null, logical(1))))
  expect_false(any(vapply(clean$replicates[!res$warned], is.null, logical(1))))

  expect_equal(nrow(pb_tidy(clean)), 2L * 27L)
  expect_equal(ncol(pb_predict_boot(clean)), 27L)
  expect_false(anyNA(pb_summary_table(clean)))
  expect_output(print(clean), "30 (3 dropped)", fixed = TRUE)
})

test_that("pb_drop_warned() removes the influence of degenerate refits", {
  # Mimic a separated replicate: flagged as warned, with a huge estimate.
  res <- boot_binomial(n = 30)
  res$warned[4] <- TRUE
  res$estimates[4, ] <- c(-5000, 250)

  expect_gt(pb_key_stats(res)$std_error[2], 10)
  expect_lt(pb_key_stats(pb_drop_warned(res))$std_error[2], 1)
})

test_that("pb_drop_warned() is a no-op without warnings and works without fits", {
  res <- pb_simulate(fit_gaussian(), n = 5, seed = 1, keep_fits = FALSE)
  expect_equal(pb_drop_warned(res), res)
})

test_that("pb_drop_warned() refuses to drop every replicate", {
  res <- suppressWarnings(
    pb_simulate(fit_binomial(), n = 3, seed = 1, control = stats::glm.control(maxit = 1))
  )
  expect_error(pb_drop_warned(res), "none would be left")
  expect_error(pb_drop_warned(list()), "pb_boot")
})
