#' Decompose model-conditional predictive variance
#'
#' For each row of `newdata`, separate variation in expected responses
#' across successful bootstrap refits from the expected response variance
#' conditional on a refit. By the law of total variance, the sum approximates
#' the variance of a new observation under the bootstrap predictive mixture.
#' Unlike [pb_predict_observations()], this function makes no random outcome
#' draws and has no simulation seed of its own.
#'
#' Supported models are the same as for [pb_predict_interval()]: unweighted
#' Gaussian `lm`, Poisson `glm`, and `MASS::glm.nb`. Both components are
#' conditional on the fitted model; they are not estimates of model
#' misspecification or exact finite-sample predictive coverage.
#'
#' @inheritParams pb_predict_observations
#' @return A data frame with `prediction`, `parameter_variance`,
#'   `observation_variance`, `total_variance`, and
#'   `successful_replicates` for each row of `newdata`.
#'   Parameter variance uses the empirical mixture denominator B, not B - 1.
#' @seealso [pb_predict_interval()], [pb_predict_observations()]
#' @examples
#' fit <- lm(mpg ~ wt + hp, data = mtcars)
#' boot <- pb_simulate(fit, n = 30, seed = 1, keep_fits = TRUE)
#' pb_predict_variance(boot, mtcars[1:2, c("wt", "hp")])
#' @export
pb_predict_variance <- function(results, newdata) {
  pb_check_boot(results)
  if (!is.data.frame(newdata) || nrow(newdata) < 1L) {
    pb_abort_validation("`newdata` must be a non-empty data frame.")
  }
  family <- pb_future_family(results$original)
  fits <- pb_fits(results)
  B <- length(fits)
  if (B < 2L) {
    pb_abort_validation("Predictive variance requires at least two successful bootstrap refits.")
  }

  n_rows <- nrow(newdata)
  means <- matrix(NA_real_, nrow = n_rows, ncol = B)
  conditional_variance <- matrix(NA_real_, nrow = n_rows, ncol = B)
  for (j in seq_along(fits)) {
    fit <- fits[[j]]
    mu <- pb_predict_one(fit, newdata, predict_args = list(type = "response"))
    if (family == "gaussian") {
      scale <- stats::sigma(fit)
      if (!is.numeric(scale) || length(scale) != 1L ||
          !is.finite(scale) || scale <= 0) {
        pb_abort("Each Gaussian refit must provide a finite positive residual standard deviation.")
      }
      variance <- rep(scale^2, n_rows)
    } else if (family == "poisson") {
      if (any(mu < 0)) pb_abort("Poisson predictions must be nonnegative.")
      variance <- mu
    } else {
      if (any(mu < 0)) pb_abort("Negative-binomial predictions must be nonnegative.")
      theta <- fit$theta
      if (!is.numeric(theta) || length(theta) != 1L ||
          !is.finite(theta) || theta <= 0) {
        pb_abort("Each negative-binomial refit must have finite positive theta.")
      }
      variance <- mu + mu^2 / theta
    }
    if (length(mu) != n_rows || any(!is.finite(mu)) ||
        any(!is.finite(variance))) {
      pb_abort("Refit predictions must provide finite numeric predictive moments.")
    }
    means[, j] <- mu
    conditional_variance[, j] <- variance
  }

  mixture_mean <- rowMeans(means)
  parameter_variance <- rowMeans((means - mixture_mean)^2)
  observation_variance <- rowMeans(conditional_variance)
  data.frame(
    prediction = pb_predict_one(results$original, newdata,
      predict_args = list(type = "response")),
    parameter_variance = parameter_variance,
    observation_variance = observation_variance,
    total_variance = parameter_variance + observation_variance,
    successful_replicates = rep(B, n_rows)
  )
}
