nested_lms <- function() {
  null <- stats::lm(mpg ~ wt + hp, data = mtcars)
  list(null = null, alternative = stats::update(null, . ~ . + drat))
}

test_that("pb_lrt() reproduces the classical likelihood-ratio test", {
  null <- fit_binomial()
  alternative <- stats::update(null, . ~ . + wt)
  test <- suppressWarnings(pb_lrt(null, alternative, n = 30, seed = 1))
  classical <- stats::anova(null, alternative, test = "LRT")

  expect_s3_class(test, "pb_lrt")
  expect_equal(test$statistic, classical$Deviance[2])
  expect_equal(test$df, 1)
  expect_equal(test$table$test, c("chisq", "bartlett", "bootstrap"))
  expect_equal(test$table$p_value[1], classical$`Pr(>Chi)`[2])
  expect_length(test$reference, 30)
  expect_true(all(test$reference >= 0))
})

test_that("p-values are computed from the reference distribution as documented", {
  models <- nested_lms()
  test <- pb_lrt(models$null, models$alternative, n = 99, seed = 1)
  reference <- test$reference

  expect_equal(test$table$p_value[3], (1 + sum(reference >= test$statistic)) / 100)
  bartlett <- test$statistic * test$df / mean(reference)
  expect_equal(test$table$statistic, c(test$statistic, bartlett, test$statistic))
  expect_equal(test$table$p_value[2], stats::pchisq(bartlett, 1, lower.tail = FALSE))
  expect_equal(test$table$df, c(1, 1, NA))
})

test_that("the bootstrap p-value converges to the exact F-test p-value", {
  skip_on_cran()
  # In the normal linear model the likelihood-ratio statistic is a monotone
  # function of the F statistic, which is pivotal, so the bootstrap test is
  # exact up to Monte Carlo error. The chi-squared p-value (0.166) is not.
  models <- nested_lms()
  exact <- stats::anova(models$null, models$alternative)$`Pr(>F)`[2]
  test <- pb_lrt(models$null, models$alternative, n = 4000, seed = 2)

  expect_equal(test$table$p_value[3], exact, tolerance = 0.1)
  expect_gt(test$table$p_value[3], test$table$p_value[1])
})

test_that("`seed` makes the test reproducible without touching the global RNG", {
  models <- nested_lms()
  first <- pb_lrt(models$null, models$alternative, n = 20, seed = 5)
  expect_equal(pb_lrt(models$null, models$alternative, n = 20, seed = 5)$reference, first$reference)
  expect_false(isTRUE(all.equal(
    pb_lrt(models$null, models$alternative, n = 20, seed = 6)$reference,
    first$reference
  )))

  set.seed(42)
  expected <- stats::runif(1)
  set.seed(42)
  pb_lrt(models$null, models$alternative, n = 5, seed = 5)
  expect_equal(stats::runif(1), expected)
})

test_that("replicates with a failed refit or a negative statistic are dropped", {
  models <- nested_lms()
  calls <- 0
  refit <- pb_refit
  local_mocked_bindings(pb_refit = function(model, ...) {
    calls <<- calls + 1
    # Each replicate refits the null and then the alternative. Call 3 is the
    # null of replicate 2: it fails, so its alternative is never refitted and
    # replicate 4 is calls 6 and 7. Swapping its two models makes the
    # statistic negative, as when the alternative converges to a worse optimum.
    if (calls == 3) stop("boom")
    if (calls == 6) {
      return(refit(models$alternative, ...))
    }
    if (calls == 7) {
      return(refit(models$null, ...))
    }
    refit(model, ...)
  })

  expect_warning(
    test <- pb_lrt(models$null, models$alternative, n = 5, seed = 1),
    "2 of 5 bootstrap refits failed and were dropped. First error: boom",
    fixed = TRUE
  )
  expect_equal(test$failed, c(FALSE, TRUE, FALSE, TRUE, FALSE))
  expect_equal(is.na(test$reference), test$failed)
  valid <- test$reference[!test$failed]
  expect_equal(test$table$p_value[3], (1 + sum(valid >= test$statistic)) / 4)
  expect_output(print(test), "5 (2 dropped)", fixed = TRUE)
  expect_no_error(ggplot2::ggplot_build(pb_plot_lrt(test)))
})

test_that("a variance component can be tested against a model without it", {
  skip_if_not_installed("lme4")
  null <- stats::lm(Yield ~ 1, data = lme4::Dyestuff)
  alternative <- lme4::lmer(Yield ~ 1 + (1 | Batch), data = lme4::Dyestuff)

  expect_message(
    test <- suppressWarnings(pb_lrt(null, alternative, n = 200, seed = 1)),
    "maximum likelihood"
  )
  expect_false(lme4::isREML(test$alternative))
  expect_equal(test$df, 1)
  expect_equal(
    test$statistic,
    2 * as.numeric(stats::logLik(test$alternative) - stats::logLik(null))
  )
  # On the boundary the statistic is exactly zero in a large share of samples,
  # so the chi-squared p-value is far too large.
  expect_gt(mean(test$reference < 1e-6), 0.4)
  expect_lt(test$table$p_value[3], test$table$p_value[1])
})

test_that("fixed effects of mixed models are tested with one message for REML fits", {
  skip_if_not_installed("lme4")
  null <- lme4::lmer(Reaction ~ 1 + (1 | Subject), data = lme4::sleepstudy)
  alternative <- lme4::lmer(Reaction ~ Days + (1 | Subject), data = lme4::sleepstudy)

  messages <- testthat::capture_messages(
    test <- suppressWarnings(pb_lrt(null, alternative, n = 9, seed = 1))
  )
  expect_length(messages, 1)
  expect_equal(test$table$p_value[3], 0.1)
  expect_lt(test$table$p_value[1], 1e-10)
  expect_output(print(test), "<2e-16", fixed = TRUE)
})

test_that("coxph models are tested on the partial likelihood", {
  skip_if_not_installed("survival")
  lung <- survival::lung
  empty <- survival::coxph(survival::Surv(time, status) ~ 1, data = lung)
  age <- survival::coxph(survival::Surv(time, status) ~ age, data = lung)
  age_sex <- survival::coxph(survival::Surv(time, status) ~ age + sex, data = lung)

  test <- pb_lrt(age, age_sex, n = 20, seed = 1)
  expect_equal(test$statistic, 2 * diff(c(age$loglik[2], age_sex$loglik[2])))
  expect_equal(test$df, 1)
  expect_false(any(test$failed))

  from_empty <- pb_lrt(empty, age, n = 20, seed = 1)
  expect_equal(from_empty$statistic, 2 * diff(age$loglik))
  expect_equal(from_empty$df, 1)
})

test_that("stratified coxph models are tested within their strata", {
  skip_if_not_installed("survival")
  lung <- survival::lung
  age <- survival::coxph(survival::Surv(time, status) ~ age + survival::strata(sex), data = lung)
  age_wt <- survival::coxph(
    survival::Surv(time, status) ~ age + pat.karno + survival::strata(sex),
    data = lung[!is.na(lung$pat.karno), ]
  )
  age <- stats::update(age, data = lung[!is.na(lung$pat.karno), ])

  test <- pb_lrt(age, age_wt, n = 20, seed = 1)
  expect_equal(test$statistic, 2 * diff(c(age$loglik[2], age_wt$loglik[2])))
  expect_false(any(test$failed))

  # Partial likelihoods built on different risk sets are not comparable.
  unstratified <- survival::coxph(
    survival::Surv(time, status) ~ age,
    data = lung[!is.na(lung$pat.karno), ]
  )
  expect_error(pb_lrt(unstratified, age_wt), "stratified in the same way")
})

test_that("pb_lrt() rejects models that cannot be compared", {
  models <- nested_lms()
  expect_error(pb_lrt(models$alternative, models$null), "Are the arguments swapped")
  expect_error(
    pb_lrt(models$null, stats::lm(mpg ~ wt + hp + drat, data = mtcars[-1, ])),
    "same observations"
  )
  expect_error(
    pb_lrt(models$null, stats::lm(log(mpg) ~ wt + hp + drat, data = mtcars)),
    "same observations"
  )
  expect_error(
    pb_lrt(stats::lm(mpg ~ wt, data = mtcars), stats::lm(mpg ~ hp + qsec, data = mtcars)),
    "does not appear to be nested"
  )
  expect_error(
    pb_lrt(
      stats::glm(vs ~ mpg, data = mtcars, family = stats::quasibinomial()),
      stats::glm(vs ~ mpg + wt, data = mtcars, family = stats::quasibinomial())
    ),
    "log-likelihood"
  )
  expect_error(pb_lrt(models$null, "not a model"), "must be fitted with")
  expect_error(pb_lrt(models$null, models$alternative, n = 0), "`n`")
  expect_error(pb_lrt(models$null, models$alternative, seed = "a"), "`seed`")
  expect_error(pb_lrt(models$null, models$alternative, workers = 0), "`workers`")

  skip_if_not_installed("survival")
  cox <- survival::coxph(survival::Surv(time, status) ~ age, data = survival::lung)
  expect_error(pb_lrt(models$null, cox), "another 'coxph' model")
})

test_that("pb_lrt() gives the same result in parallel", {
  skip_on_cran()
  skip_if_not("parametricboot" %in% rownames(utils::installed.packages()))
  models <- nested_lms()
  expect_equal(
    pb_lrt(models$null, models$alternative, n = 8, seed = 1, workers = 2)$reference,
    pb_lrt(models$null, models$alternative, n = 8, seed = 1)$reference
  )
})

test_that("print() and pb_plot_lrt() describe the test", {
  models <- nested_lms()
  test <- pb_lrt(models$null, models$alternative, n = 50, seed = 1)

  expect_output(print(test), "<pb_lrt> Parametric bootstrap likelihood-ratio test")
  expect_output(print(test), "Null:        mpg ~ wt + hp", fixed = TRUE)
  expect_output(print(test), "on 1 df", fixed = TRUE)
  expect_output(print(test), "Parametric bootstrap", fixed = TRUE)
  utils::capture.output(printed <- withVisible(print(test)))
  expect_false(printed$visible)

  plot <- pb_plot_lrt(test, bins = 20)
  expect_s3_class(plot, "ggplot")
  expect_no_error(ggplot2::ggplot_build(plot))
  expect_equal(nrow(plot$data), 20L)
  expect_equal(sum(plot$data$count), 50)
  # The expected counts are those of the chi-squared approximation.
  expect_lte(sum(plot$data$expected), 50)
  expect_gt(sum(plot$data$expected), 49)

  expect_error(pb_plot_lrt(boot_binomial(n = 3)), "pb_lrt")
  expect_error(pb_plot_lrt(test, bins = 0), "`bins`")
})

test_that("per-replicate messages from refits are muffled", {
  skip_if_not_installed("lme4")
  # Simulating from a model without the random effect makes most refits
  # singular, which 'lme4' reports with a message for every fit.
  null <- stats::lm(Yield ~ 1, data = lme4::Dyestuff)
  alternative <- lme4::lmer(Yield ~ 1 + (1 | Batch), data = lme4::Dyestuff, REML = FALSE)
  expect_no_message(suppressWarnings(pb_lrt(null, alternative, n = 10, seed = 1)))
})
