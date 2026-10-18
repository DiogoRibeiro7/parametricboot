test_that("budworm LD50 callback agrees with an independent probability inversion", {
  budworm <- data.frame(
    sex = rep(c("M", "F"), each = 6),
    dose = rep(c(1, 2, 4, 8, 16, 32), times = 2),
    dead = c(1, 4, 9, 13, 18, 20, 0, 2, 6, 10, 12, 16),
    n = 20
  )
  fit <- stats::glm(cbind(dead, n - dead) ~ sex + log2(dose),
                    data = budworm, family = stats::binomial())
  ld50 <- function(model) {
    b <- stats::coef(model)
    slope <- unname(b[["log2(dose)"]])
    c(
      female_LD50 = 2^(-unname(b[["(Intercept)"]]) / slope),
      male_LD50 = 2^(
        -(unname(b[["(Intercept)"]]) + unname(b[["sexM"]])) / slope
      )
    )
  }
  original <- ld50(fit)
  expect_true(all(is.finite(original) & original > 0))
  expected_probability <- stats::predict(
    fit, newdata = data.frame(sex = c("F", "M"), dose = unname(original)),
    type = "response"
  )
  expect_equal(unname(expected_probability), c(0.5, 0.5), tolerance = 1e-10)
  result <- suppressWarnings(pb_simulate(
    fit, n = 80, seed = 2025, keep_fits = FALSE, statistic = ld50
  ))
  expect_null(result$replicates)
  expect_equal(colnames(result$estimates), names(original))
  expect_equal(pb_confint(result)$estimate, unname(original))
  expect_true(all(is.finite(pb_confint(result)$lower)))
  expect_equal(pb_mc_error(result)$term, names(original))
})

test_that("Gaussian contrast bootstrap-t approaches an exact t interval", {
  fit <- stats::lm(mpg ~ wt + hp, data = mtcars)
  statistic <- function(model) {
    c(wt_plus_hp = unname(sum(stats::coef(model)[c("wt", "hp")])))
  }
  statistic_se <- function(model) {
    w <- c(0, 1, 1)
    V <- stats::vcov(model)
    c(wt_plus_hp = sqrt(unname(drop(crossprod(w, V %*% w)))))
  }
  ref <- unname(statistic(fit))
  ref_se <- unname(statistic_se(fit))
  exact <- ref + c(-1, 1) *
    stats::qt(0.975, stats::df.residual(fit)) * ref_se
  result <- pb_simulate(fit, n = 1600, seed = 173,
                        keep_fits = FALSE, statistic = statistic,
                        statistic_se = statistic_se)
  interval <- pb_confint(result, type = "student")
  expect_equal(c(interval$lower, interval$upper), exact, tolerance = 0.15)
  observed_t <- (result$estimates[, 1] - ref) / result$std_errors[, 1]
  expect_equal(stats::sd(observed_t),
               sqrt(stats::df.residual(fit) /
                    (stats::df.residual(fit) - 2)), tolerance = 0.12)
  expect_equal(pb_confint(result, type = "student"),
               pb_confint(result, type = "student"))
  expect_equal(result$statistic_se_estimate, statistic_se(fit))
})
