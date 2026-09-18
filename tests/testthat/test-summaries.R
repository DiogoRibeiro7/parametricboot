test_that("pb_confint() returns ordered intervals of every type", {
  res <- boot_binomial(n = 50)
  for (type in c("percentile", "basic", "normal")) {
    ci <- pb_confint(res, type = type)
    expect_named(ci, c("term", "estimate", "lower", "upper"))
    expect_equal(ci$term, c("(Intercept)", "mpg"))
    expect_equal(ci$estimate, unname(stats::coef(res$original)))
    expect_true(all(ci$lower < ci$upper))
  }
})

test_that("pb_confint() matches hand-computed intervals", {
  res <- boot_binomial(n = 50)
  mpg <- res$estimates[, "mpg"]
  theta <- unname(stats::coef(res$original)["mpg"])
  q <- unname(stats::quantile(mpg, c(0.05, 0.95)))

  percentile <- pb_confint(res, level = 0.9)
  expect_equal(c(percentile$lower[2], percentile$upper[2]), q)

  basic <- pb_confint(res, level = 0.9, type = "basic")
  expect_equal(c(basic$lower[2], basic$upper[2]), 2 * theta - rev(q))

  normal <- pb_confint(res, level = 0.9, type = "normal")
  centre <- 2 * theta - mean(mpg)
  expect_equal(
    c(normal$lower[2], normal$upper[2]),
    centre + c(-1, 1) * stats::qnorm(0.95) * stats::sd(mpg)
  )
})

test_that("wider levels give wider intervals", {
  res <- boot_binomial(n = 50)
  narrow <- pb_confint(res, level = 0.5)
  wide <- pb_confint(res, level = 0.99)
  expect_true(all(wide$upper - wide$lower > narrow$upper - narrow$lower))
})

test_that("pb_key_stats() matches hand-computed statistics", {
  res <- boot_binomial(n = 50)
  key_stats <- pb_key_stats(res)
  mpg <- res$estimates[, "mpg"]
  se <- res$std_errors[, "mpg"]
  theta <- unname(stats::coef(res$original)["mpg"])

  expect_named(
    key_stats,
    c("term", "estimate", "boot_mean", "bias", "std_error", "mse", "coverage")
  )
  expect_equal(key_stats$bias[2], mean(mpg) - theta)
  expect_equal(key_stats$std_error[2], stats::sd(mpg))
  expect_equal(key_stats$mse[2], mean((mpg - theta)^2))
  expect_equal(key_stats$coverage[2], mean(abs(mpg - theta) <= stats::qnorm(0.975) * se))
  expect_true(all(key_stats$coverage >= 0 & key_stats$coverage <= 1))
})

test_that("pb_summary_table() combines statistics and intervals", {
  res <- boot_binomial(n = 50)
  tbl <- pb_summary_table(res, level = 0.9, type = "basic")
  expect_equal(nrow(tbl), 2L)
  expect_equal(tbl[names(pb_key_stats(res))], pb_key_stats(res, level = 0.9))
  expect_equal(tbl$lower, pb_confint(res, level = 0.9, type = "basic")$lower)
})

test_that("pb_tidy() returns one row per replicate and term", {
  res <- boot_binomial(n = 7)
  tidy <- pb_tidy(res)
  expect_named(tidy, c("replicate", "term", "estimate"))
  expect_equal(nrow(tidy), 14L)
  expect_equal(tidy$estimate[tidy$term == "mpg"], unname(res$estimates[, "mpg"]))
  expect_equal(tidy$replicate[tidy$term == "mpg"], 1:7)
})

test_that("failed replicates are excluded from every summary", {
  res <- boot_binomial(n = 10)
  res$failed[c(2, 5)] <- TRUE
  res$estimates[c(2, 5), ] <- NA
  res$std_errors[c(2, 5), ] <- NA
  res$replicates[c(2, 5)] <- list(NULL)

  expect_equal(sort(unique(pb_tidy(res)$replicate)), c(1, 3, 4, 6:10))
  expect_false(anyNA(pb_summary_table(res)))
  expect_equal(ncol(pb_predict_boot(res)), 8L)
  expect_output(print(res), "2 dropped")
})

test_that("summaries validate their inputs", {
  res <- boot_binomial(n = 5)
  expect_error(pb_confint(list()), "pb_boot")
  expect_error(pb_key_stats(1), "pb_boot")
  expect_error(pb_tidy(NULL), "pb_boot")
  expect_error(pb_confint(res, level = 1), "`level`")
  expect_error(pb_confint(res, level = c(0.9, 0.95)), "`level`")
  expect_error(pb_confint(res, type = "bca"), "should be one of")
})
