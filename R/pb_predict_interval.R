#' Simulate future observations from parametric bootstrap refits
#'
#' The existing [pb_predict_boot()] reports predictions of the conditional
#' mean. This function also draws a new response for every successful refit,
#' combining variation of the fitted model with response/process noise.
#' Each column corresponds to one independently simulated bootstrap refit
#' and includes one newly simulated observation for each row of `newdata`.
#'
#' Initially supported: unweighted Gaussian `stats::lm()`, unweighted
#' Poisson `stats::glm()`, and unweighted `MASS::glm.nb()`.
#' Gaussian outcomes use each refit's residual standard deviation; Poisson
#' and negative-binomial outcomes use each refit's fitted conditional mean,
#' with the latter also using the refit's re-estimated dispersion.
#' Binomial, mixed-effects and Cox models are explicitly unsupported because
#' their observation-level sampling assumptions require separate validation.
#' Results must retain refits (`keep_fits = TRUE`). Cached conditional
#' means alone are not sufficient to reconstruct all observation-level
#' distributions. This is a model-conditional predictive simulation, not
#' an exact small-sample frequentist prediction interval.
#'
#' @param results A pb_boot object from [pb_simulate()] or [pb_parallel()],
#'   created with `keep_fits = TRUE`.
#' @param newdata Nonempty data frame giving the covariates of future
#'   observations. The fitted model must be able to predict for each row.
#' @param seed Optional RNG seed for the new-outcome draws, independent of
#'   the seed used to generate the bootstrap refits.
#' @return A numeric matrix with one row per future observation and one
#'   column per successful bootstrap refit. Entries are independent
#'   conditional draws from each fitted refit's sampling model.
#' @seealso [pb_predict_interval()], [pb_predict_boot()]
#' @examples
#' fit <- lm(mpg ~ wt + hp, data = mtcars)
#' boot <- pb_simulate(fit, n = 30, seed = 1, keep_fits = TRUE)
#' new_cars <- mtcars[1:2, c("wt", "hp")]
#' draws <- pb_predict_observations(boot, new_cars, seed = 2)
#' dim(draws)
#' @export
pb_predict_observations <- function(results, newdata, seed = NULL) {
  pb_check_boot(results)
  if (!is.data.frame(newdata) || nrow(newdata) < 1L) {
    pb_abort_validation("`newdata` must be a non-empty data frame.")
  }
  pb_check_seed(seed)
  family <- pb_future_family(results$original)
  fits <- pb_fits(results)
  B <- length(fits)
  if (B < 2L) {
    pb_abort_validation("Future-observation intervals require at least two successful bootstrap refits.")
  }
  n_rows <- nrow(newdata)
  samples <- pb_with_seed(seed, lapply(fits, function(fit) {
    mu <- pb_predict_one(fit, newdata, predict_args = list(type = "response"))
    if (family == "gaussian") {
      scale <- stats::sigma(fit)
      if (!is.numeric(scale) || length(scale) != 1L ||
          !is.finite(scale) || scale <= 0) {
        pb_abort("Each Gaussian refit must provide a finite positive residual standard deviation.")
      }
      stats::rnorm(n_rows, mean = mu, sd = scale)
    } else if (family == "poisson") {
      if (any(mu < 0)) pb_abort("Poisson predictions must be nonnegative.")
      stats::rpois(n_rows, lambda = mu)
    } else {
      if (any(mu < 0)) pb_abort("Negative-binomial predictions must be nonnegative.")
      theta <- fit$theta
      if (!is.numeric(theta) || length(theta) != 1L ||
          !is.finite(theta) || theta <= 0) {
        pb_abort("Each negative-binomial refit must have finite positive theta.")
      }
      stats::rnbinom(n_rows, size = theta, mu = mu)
    }
  }))
  matrix(as.numeric(unlist(samples, use.names = FALSE)), nrow = n_rows,
         ncol = B)
}

# Reject unsupported predictive response models or weights before drawing.
# Treating a conditional mean as a future observation would understate spread.
pb_future_family <- function(model) {
  kind <- pb_model_type(model)
  if (identical(class(model), "lm")) {
    weights <- model$weights
    if (!is.null(weights) && (!is.numeric(weights) ||
        any(!is.finite(weights)) || any(weights != 1))) {
      pb_abort_validation(
        "Future Gaussian observations with non-unit weights are unsupported: future observation weights are not specified."
      )
    }
    return("gaussian")
  }
  if (kind == "negbin") return("negative_binomial")
  if (identical(class(model), c("glm", "lm")) &&
      identical(stats::family(model)$family, "poisson")) {
    weights <- model$prior.weights
    if (!is.null(weights) && (!is.numeric(weights) ||
        any(!is.finite(weights)) || any(weights != 1))) {
      pb_abort_validation(
        "Future Poisson observations with non-unit weights are unsupported."
      )
    }
    return("poisson")
  }
  pb_abort_validation(
    "Future-observation prediction currently supports unweighted Gaussian lm, Poisson glm, or MASS::glm.nb() models only."
  )
}

#' Prediction intervals for new observations
#'
#' Combines variation of the fitted model across parametric bootstrap refits
#' with a new draw of observation-level response noise for every refit.
#' The returned limits are empirical quantiles of those future outcomes,
#' rather than confidence intervals for conditional expected responses.
#' The `prediction` column is the original model's expected response.
#'
#' These intervals are conditional on the assumed response model and
#' approximate in both sample size and number of bootstrap simulations.
#' They do not guarantee exact finite-sample coverage. Unlike conditional
#' mean predictions, they require retained refitted models.
#'
#' @inheritParams pb_predict_observations
#' @param level Predictive quantile interval level, strictly between 0 and 1.
#' @return A data frame with `prediction` (original model expected response),
#'   `lower`, `upper`, and `successful_replicates`, one row per new
#'   observation.
#' @seealso [pb_predict_observations()], [pb_predict_boot()]
#' @examples
#' fit <- lm(mpg ~ wt + hp, data = mtcars)
#' boot <- pb_simulate(fit, n = 30, seed = 1)
#' pb_predict_interval(boot, mtcars[1:2, c("wt", "hp")], level = 0.9,
#'                     seed = 2)
#' @export
pb_predict_interval <- function(results, newdata, level = 0.95,
                                seed = NULL) {
  level <- pb_check_level(level)
  draws <- pb_predict_observations(results, newdata, seed = seed)
  probabilities <- c((1 - level) / 2, (1 + level) / 2)
  quantiles <- matrix(
    unlist(lapply(seq_len(nrow(draws)), function(i) {
      stats::quantile(draws[i, ], probs = probabilities, names = FALSE)
    }), use.names = FALSE),
    nrow = 2L, ncol = nrow(draws)
  )
  expected <- pb_predict_one(
    results$original, newdata, predict_args = list(type = "response")
  )
  data.frame(
    prediction = expected,
    lower = unname(quantiles[1L, ]),
    upper = unname(quantiles[2L, ]),
    successful_replicates = rep(ncol(draws), nrow(draws)),
    stringsAsFactors = FALSE
  )
}
