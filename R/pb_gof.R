#' Parametric-bootstrap goodness-of-fit test for count and binomial GLMs
#'
#' Simulate responses from the fitted model, refit the same model, and
#' recompute the deviance or Pearson statistic. This is a conditional,
#' model-based goodness-of-fit check, not a test of the correctness of
#' the fitted sampling family. The tail p-value uses an add-one correction.
#' Refits that fail are excluded and reported. The alternative tail may
#' be selected explicitly: `"greater"` checks for unusually large
#' discrepancies or excess zeros, while `"less"` checks for unusually small
#' discrepancies or a deficit of zeros. Discreteness and ties are retained.
#' Neither direction constitutes a two-sided test.
#'
#' @param model A supported, unweighted binomial, Poisson or
#'   MASS negative-binomial regression fit.
#' @param n Number of bootstrap replicates.
#' @param statistic One of "deviance", "pearson", or "zeros".
#'   "zeros" counts zero responses and is available only for unweighted
#'   Poisson and negative-binomial fits without transformed responses.
#' @param seed Optional seed, preserving the calling session's RNG state.
#' @param workers Number of refitting processes.
#' @param tail Reference-distribution tail, `"greater"` (default) or
#'   `"less"`. Both include values equal to the observed statistic.
#'   Use `"less"` with `statistic = "zeros"` to investigate a deficit
#'   rather than an excess of zero counts.
#' @return An object of class pb_gof with statistic, observed, reference,
#'   p_value, tail, n, failed, warned, model, seed and call.
#' @seealso [pb_gof_mc_error()] for conditional Monte Carlo precision and
#'   [pb_plot_gof()] to inspect the simulated reference distribution.
#' @examples
#' fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
#' pb_gof(fit, n = 30, seed = 1)
#' @export
pb_gof <- function(model, n = 1000, statistic = c("deviance", "pearson", "zeros"),
                   seed = NULL, workers = 1L,
                   tail = c("greater", "less")) {
  call <- match.call()
  type <- pb_model_type(model)
  if (!type %in% c("lm", "negbin") || !inherits(model, "glm")) {
    pb_abort_validation("Goodness-of-fit tests currently require a supported GLM or MASS::glm.nb() model.")
  }
  family <- stats::family(model)$family
  count <- identical(family, "poisson") || type == "negbin"
  if (!count && !identical(family, "binomial")) {
    pb_abort_validation("Goodness-of-fit requires binomial, Poisson or negative-binomial sampling.")
  }
  statistic <- match.arg(statistic)
  tail <- match.arg(tail)
  n <- pb_check_count(n, "n")
  workers <- pb_check_count(workers, "workers")
  pb_check_seed(seed)
  if (statistic == "zeros") {
    if (!count || !is.null(model$prior.weights) &&
        any(model$prior.weights != 1)) {
      pb_abort_validation("Zero-count goodness-of-fit requires an unweighted count model.")
    }
    response <- stats::model.response(stats::model.frame(model))
    if (!is.numeric(response) || is.matrix(response) ||
        any(!is.finite(response)) || any(response < 0) ||
        any(response != floor(response))) {
      pb_abort_validation("Zero-count goodness-of-fit requires nonnegative integer responses.")
    }
  }
  observed <- pb_gof_stat(model, statistic)
  aux <- pb_refit_data(model)
  responses <- pb_with_seed(seed, pb_sim_response(model, type, n))
  out <- pb_lapply(responses, pb_gof_one, model = model, type = type,
                   aux = aux, statistic = statistic, workers = workers)
  failed <- vapply(out, function(x) !is.null(x$error), logical(1))
  warned <- vapply(out, function(x) x$warned, logical(1))
  if (all(failed)) {
    pb_abort("All ", n, " goodness-of-fit bootstrap refits failed. First error: ",
             out[[1L]]$error)
  }
  pb_warn_replicates(failed, warned, out)
  reference <- rep(NA_real_, n)
  reference[!failed] <- vapply(out[!failed], function(x) x$value, numeric(1))
  valid <- reference[!failed]
  exceedances <- if (tail == "greater") sum(valid >= observed) else
    sum(valid <= observed)
  p_value <- (1 + exceedances) / (1 + length(valid))
  structure(list(statistic = statistic, observed = observed, reference = reference,
                 p_value = p_value, tail = tail, n = n,
                 failed = failed, warned = warned,
                 model = model, seed = seed, call = call), class = "pb_gof")
}

pb_gof_stat <- function(model, statistic) {
  value <- switch(statistic,
    deviance = stats::deviance(model),
    pearson = sum(stats::residuals(model, type = "pearson")^2),
    zeros = sum(stats::model.response(stats::model.frame(model)) == 0)
  )
  if (!is.numeric(value) || length(value) != 1L || !is.finite(value) ||
      value < 0) stop("Non-finite goodness-of-fit statistic.")
  unname(as.numeric(value))
}

pb_gof_one <- function(response, model, type, aux, statistic) {
  out <- pb_safely(function() {
    fit <- pb_refit(model, type, response, aux, dots = list())
    pb_gof_stat(fit, statistic)
  })
  list(value = out$value, warned = out$warned, error = out$error)
}


# Recover the finite reference distribution and the chosen tail from either a
# new pb_gof object or an older one made before the tail parameter existed.
pb_gof_reference <- function(test) {
  if (!inherits(test, "pb_gof") ||
      !is.numeric(test$observed) || length(test$observed) != 1L ||
      !is.finite(test$observed) ||
      !is.numeric(test$reference) || !is.logical(test$failed) ||
      anyNA(test$failed) || length(test$reference) != length(test$failed) ||
      any(!is.finite(test$reference[!test$failed]))) {
    pb_abort_validation("`test` must be a valid pb_gof object.")
  }
  tail <- if (is.null(test$tail)) "greater" else test$tail
  if (!is.character(tail) || length(tail) != 1L ||
      is.na(tail) || !(tail %in% c("greater", "less"))) {
    pb_abort_validation("`test` has an invalid tail direction.")
  }
  valid <- test$reference[!test$failed]
  if (!length(valid)) {
    pb_abort_validation("The goodness-of-fit test has no valid bootstrap replicates.")
  }
  list(valid = valid, tail = tail)
}

#' Monte Carlo uncertainty of a bootstrap goodness-of-fit p-value
#'
#' The reported bootstrap p-value retains the add-one correction:
#' \eqn{(k + 1) / (B + 1)}, where \eqn{k} is the tail-exceedance count
#' and \eqn{B} is the number of successful refits. The plug-in
#' Monte Carlo standard error \eqn{\sqrt{(k/B)(1-k/B)/B}} and the exact
#' Clopper-Pearson confidence limits refer instead to the *uncorrected*
#' tail probability \eqn{k/B}. At zero exceedances the plug-in standard
#' error is zero, but the exact upper confidence limit remains positive.
#'
#' This is only Monte Carlo uncertainty conditional on independent,
#' successful refits and the fitted model. It does not account for model
#' misspecification or bias from selectively failed refits.
#'
#' @param test An object created by [pb_gof()].
#' @param level Confidence level for the exact binomial interval.
#' @return One-row data frame with tail, p_value, tail_probability,
#'   mc_standard_error, lower, upper, exceedances, valid_replicates, and
#'   failed_replicates. The lower and upper limits refer to the raw tail
#'   probability, not the add-one corrected p-value.
#' @seealso [pb_plot_gof()], [pb_lrt_mc_error()]
#' @examples
#' fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
#' check <- pb_gof(fit, n = 30, seed = 1)
#' pb_gof_mc_error(check)
#' @export
pb_gof_mc_error <- function(test, level = 0.95) {
  details <- pb_gof_reference(test)
  level <- pb_check_level(level)
  B <- length(details$valid)
  k <- if (details$tail == "greater") {
    sum(details$valid >= test$observed)
  } else {
    sum(details$valid <= test$observed)
  }
  probability <- k / B
  interval <- stats::binom.test(k, B, conf.level = level)$conf.int
  data.frame(
    tail = details$tail,
    p_value = (k + 1) / (B + 1),
    tail_probability = probability,
    mc_standard_error = sqrt(probability * (1 - probability) / B),
    lower = unname(interval[[1L]]),
    upper = unname(interval[[2L]]),
    exceedances = as.integer(k),
    valid_replicates = as.integer(B),
    failed_replicates = as.integer(sum(test$failed)),
    stringsAsFactors = FALSE
  )
}

#' Plot a simulated goodness-of-fit reference distribution
#'
#' Displays valid bootstrap statistics and the observed statistic with a
#' vertical line. Inspecting the histogram helps identify discreteness,
#' ties or an unexpectedly skewed reference distribution. This is a plot
#' of the reference distribution, not a chi-squared approximation.
#'
#' @param test An object created by [pb_gof()].
#' @param bins Positive number of histogram bins.
#' @return A ggplot object.
#' @seealso [pb_gof()], [pb_gof_mc_error()]
#' @examples
#' fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
#' check <- pb_gof(fit, n = 30, seed = 1)
#' pb_plot_gof(check)
#' @export
pb_plot_gof <- function(test, bins = 30L) {
  details <- pb_gof_reference(test)
  bins <- pb_check_count(bins, "bins")
  plot_data <- data.frame(value = details$valid)
  ggplot2::ggplot(plot_data, ggplot2::aes(x = .data$value)) +
    ggplot2::geom_histogram(
      bins = bins, fill = "steelblue", colour = "white", alpha = 0.8
    ) +
    ggplot2::geom_vline(xintercept = test$observed, linetype = "dashed",
                        linewidth = 0.8) +
    ggplot2::labs(
      title = "Bootstrap goodness-of-fit reference distribution",
      subtitle = paste0(
        "Statistic: ", test$statistic, "; tail: ", details$tail,
        "; valid refits: ", length(details$valid),
        "; dashed line: observed"
      ),
      x = "Simulated goodness-of-fit statistic", y = "Replicates"
    ) +
    ggplot2::theme_minimal()
}
