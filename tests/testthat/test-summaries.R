test_that("pb_confint() returns ordered intervals of every type", {
  res <- boot_binomial(n = 50)
  for (type in c("percentile", "basic", "normal", "student")) {
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

test_that("studentised intervals match the hand-computed bootstrap-t interval", {
  res <- boot_binomial(n = 50)
  theta <- unname(stats::coef(res$original)["mpg"])
  se <- unname(sqrt(diag(stats::vcov(res$original)))["mpg"])
  z <- (res$estimates[, "mpg"] - theta) / res$std_errors[, "mpg"]
  q <- unname(stats::quantile(z, c(0.05, 0.95)))

  student <- pb_confint(res, level = 0.9, type = "student")
  expect_equal(c(student$lower[2], student$upper[2]), theta - se * rev(q))
  expect_equal(unname(confint(res, level = 0.9, type = "student")["mpg", ]), theta - se * rev(q))
  expect_equal(
    pb_summary_table(res, level = 0.9, type = "student")$upper,
    student$upper
  )
})

test_that("studentised intervals reproduce the exact t interval of a linear model", {
  skip_on_cran()
  # (estimate - truth) / se is an exact t pivot in the normal linear model, so
  # the bootstrap-t interval is exact up to Monte Carlo error. The percentile
  # interval has no such correction and is too narrow.
  fit <- fit_gaussian()
  res <- pb_simulate(fit, n = 4000, seed = 3, keep_fits = FALSE)
  exact <- unname(stats::confint(fit))

  student <- pb_confint(res, type = "student")
  expect_equal(cbind(student$lower, student$upper), exact, tolerance = 0.05)

  percentile <- pb_confint(res)
  expect_true(all(percentile$upper - percentile$lower < exact[, 2] - exact[, 1]))
})

test_that("studentised intervals are insensitive to degenerate refits", {
  # A separated logistic fit has a huge estimate and an even larger standard
  # error, so its studentised value is unremarkable.
  res <- boot_binomial(n = 50)
  before <- pb_confint(res, type = "student")
  res$estimates[7, ] <- c(-5000, 250)
  res$std_errors[7, ] <- c(4e6, 2e5)

  expect_equal(pb_confint(res, type = "student"), before, tolerance = 0.1)
  expect_gt(diff(unlist(pb_confint(res, type = "normal")[2, c("lower", "upper")])), 50)
})

test_that("studentised intervals need the standard errors of the refits", {
  res <- boot_binomial(n = 10)
  res$std_errors[] <- NA
  expect_error(pb_confint(res, type = "student"), "standard errors")
  expect_no_error(pb_confint(res, type = "percentile"))
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
