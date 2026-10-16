# Monte Carlo precision of estimates drawn from the fitted parametric model.
# Keep these diagnostics separate from the sampling uncertainty of the model.

.pb_mc_estimates <- function(results) {
  pb_check_boot(results)
  x <- results$estimates
  failed <- results$failed
  if (!is.matrix(x) || !is.numeric(x) || is.null(colnames(x)) ||
      !is.logical(failed) || anyNA(failed) || length(failed) != nrow(x)) {
    pb_abort_validation("Malformed pb_boot estimates or failed-replicate flags.")
  }
  x[!failed, , drop = FALSE]
}

#' Monte Carlo errors of bootstrap bias and standard error
#'
#' The bootstrap standard error is the standard deviation of successful,
#' finite replicate estimates. For each parameter with B usable estimates,
#' the Monte Carlo standard error of bootstrap bias is s / sqrt(B), where s
#' is the bootstrap standard error; the fitted original estimate is held
#' fixed. The reported Monte Carlo standard error for s uses a first-order
#' delta-method estimate based on the empirical fourth central moment:
#' s * sd(((theta_star - mean(theta_star)) / s)^2) / (2 * sqrt(B)).
#'
#' The latter is not estimated for fewer than four finite replicates or
#' zero sample dispersion; NA is returned instead of asserting false
#' precision. Replicates with missing/non-finite parameter estimates and
#' failed model refits are excluded, separately for each parameter.
#' Estimates are conditional on the fitted model and the retained refits:
#' this does not quantify model misspecification, selective refit failure,
#' or the frequentist sampling error of the original fit.
#'
#' @param results A pb_boot object from [pb_simulate()] or [pb_parallel()].
#' @return A data frame with term, replicates, failed_replicates, bias,
#'   bias_mc_se, std_error and std_error_mc_se. The unqualified std_error
#'   is the ordinary bootstrap standard deviation, NOT the Monte Carlo error.
#' @seealso [pb_key_stats()], [pb_confint_mc_error()], [pb_lrt_mc_error()]
#' @examples
#' model <- lm(mpg ~ wt, data = mtcars)
#' result <- pb_simulate(model, n = 30, seed = 7, keep_fits = FALSE)
#' pb_mc_error(result)
#' @export
pb_mc_error <- function(results) {
  x <- .pb_mc_estimates(results)
  theta <- pb_coef(results$original)
  if (!identical(colnames(x), names(theta))) {
    pb_abort_validation("Bootstrap parameter names do not match the fitted model.")
  }
  n_terms <- ncol(x)
  out <- data.frame(
    term = names(theta),
    replicates = integer(n_terms),
    failed_replicates = rep(as.integer(sum(results$failed)), n_terms),
    bias = rep(NA_real_, n_terms),
    bias_mc_se = rep(NA_real_, n_terms),
    std_error = rep(NA_real_, n_terms),
    std_error_mc_se = rep(NA_real_, n_terms),
    stringsAsFactors = FALSE
  )
  for (j in seq_len(n_terms)) {
    values <- x[, j]
    values <- values[is.finite(values)]
    B <- length(values)
    out$replicates[j] <- B
    if (!B) next
    out$bias[j] <- mean(values) - theta[j]
    if (B < 2L) next
    s <- stats::sd(values)
    out$std_error[j] <- s
    if (!is.finite(s)) next
    out$bias_mc_se[j] <- s / sqrt(B)
    if (B >= 4L && s > 0) {
      # Dimensionless fourth-moment estimate, scaled back to original units.
      normalized_squared <- ((values - mean(values)) / s)^2
      if (all(is.finite(normalized_squared))) {
        out$std_error_mc_se[j] <-
          s * stats::sd(normalized_squared) / (2 * sqrt(B))
      }
    }
  }
  out
}

# Exact nonparametric rank-based Monte Carlo bounds for a bootstrap quantile.
# If K counts observations at or below the true p-quantile, K has a binomial
# bound with probability p. qbinom cutoffs give conservative tails even with
# ties. Rank zero or B+1 requires an unbounded endpoint, not extrapolation.
.pb_mc_rank_bounds <- function(values, probability, mc_level) {
  values <- sort(values[is.finite(values)])
  B <- length(values)
  if (!B) return(c(NA_real_, NA_real_))
  tail_probability <- (1 - mc_level) / 2
  lower_index <- as.integer(stats::qbinom(tail_probability, B, probability))
  upper_index <- as.integer(
    stats::qbinom(1 - tail_probability, B, probability)
  ) + 1L
  c(
    if (lower_index == 0L) -Inf else values[lower_index],
    if (upper_index > B) Inf else values[upper_index]
  )
}

#' Monte Carlo precision of bootstrap confidence interval limits
#'
#' For percentile, basic and studentised confidence intervals, calculate
#' distribution-free order-statistic bounds for EACH interval endpoint.
#' These bounds describe the Monte Carlo uncertainty of the underlying
#' bootstrap quantiles, conditional on the successful finite refits.
#' They are not confidence intervals for the unknown model parameter, and
#' are not a simultaneous confidence region for both interval limits.
#'
#' Very few replicates (particularly for extreme tail probabilities) can
#' produce infinite Monte Carlo bounds, correctly indicating that no
#' finite bound is justified without a distributional assumption.
#' For studentised intervals the rank bounds apply to the finite bootstrap
#' pivot and are mapped into coefficient units using the original model
#' standard error. Parameters lacking a usable studentised interval retain
#' NA bounds. Normal-approximation intervals have a different joint
#' uncertainty structure and are not supported by this rank-based function.
#'
#' @param results A pb_boot object from [pb_simulate()] or [pb_parallel()].
#' @param level Coverage level of the existing bootstrap confidence interval.
#' @param type One of "percentile", "basic", or "student". Unlike
#'   [pb_confint()], the "normal" interval is not supported.
#' @param mc_level Per-endpoint Monte Carlo confidence level for the rank
#'   bounds, distinct from the statistical confidence interval level.
#' @return A data frame with term, lower, upper, lower_mc_low,
#'   lower_mc_high, upper_mc_low, upper_mc_high and replicates. lower and
#'   upper are the UNCHANGED limits from [pb_confint()]; the *_mc_* fields
#'   bound Monte Carlo uncertainty for each limit separately.
#' @seealso [pb_confint()], [pb_mc_error()], [pb_lrt_mc_error()]
#' @examples
#' model <- lm(mpg ~ wt, data = mtcars)
#' result <- pb_simulate(model, n = 30, seed = 7, keep_fits = FALSE)
#' pb_confint_mc_error(result, level = 0.8, mc_level = 0.9)
#' @export
pb_confint_mc_error <- function(
    results, level = 0.95, type = c("percentile", "basic", "student"),
    mc_level = 0.95) {
  x <- .pb_mc_estimates(results)
  level <- pb_check_level(level)
  mc_level <- pb_check_level(mc_level)
  type <- match.arg(type)
  theta <- pb_coef(results$original)
  if (!identical(colnames(x), names(theta))) {
    pb_abort_validation("Bootstrap parameter names do not match the fitted model.")
  }
  ci <- pb_confint(results, level = level, type = type)
  n_terms <- ncol(x)
  pivot_scale <- NULL
  if (type == "student") {
    se <- results$std_errors
    if (!is.matrix(se) || !identical(dim(se), dim(results$estimates))) {
      pb_abort_validation("Malformed bootstrap standard errors.")
    }
    x <- sweep(x, 2, theta) / se[!results$failed, , drop = FALSE]
    x[!is.finite(x)] <- NA_real_
    pivot_scale <- pb_se(results$original)
  }
  out <- data.frame(
    term = ci$term,
    lower = ci$lower,
    upper = ci$upper,
    lower_mc_low = rep(NA_real_, n_terms),
    lower_mc_high = rep(NA_real_, n_terms),
    upper_mc_low = rep(NA_real_, n_terms),
    upper_mc_high = rep(NA_real_, n_terms),
    replicates = integer(n_terms),
    stringsAsFactors = FALSE
  )
  probability <- (1 - level) / 2
  for (j in seq_len(n_terms)) {
    values <- x[, j]
    out$replicates[j] <- sum(is.finite(values))
    if (!out$replicates[j] || anyNA(c(ci$lower[j], ci$upper[j]))) next
    low_quantile <- .pb_mc_rank_bounds(values, probability, mc_level)
    high_quantile <- .pb_mc_rank_bounds(values, 1 - probability, mc_level)
    if (type == "percentile") {
      bounds <- c(low_quantile, high_quantile)
    } else {
      scale <- if (type == "basic") 1 else pivot_scale[j]
      if (!is.finite(scale) || scale < 0) next
      if (scale == 0) {
        bounds <- rep(theta[j], 4L)
      } else {
        bounds <- c(
          2 * theta[j] - scale * high_quantile[2L],
          2 * theta[j] - scale * high_quantile[1L],
          2 * theta[j] - scale * low_quantile[2L],
          2 * theta[j] - scale * low_quantile[1L]
        )
        if (type == "student") {
          # Studentised limits are theta - se * quantile, not 2*theta - se*quantile.
          bounds <- bounds - theta[j]
        }
      }
    }
    out[j, c("lower_mc_low", "lower_mc_high",
             "upper_mc_low", "upper_mc_high")] <- bounds
  }
  out
}
