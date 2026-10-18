#' Parametric-bootstrap goodness-of-fit test for count and binomial GLMs
#'
#' Simulate responses from the fitted model, refit the same model, and
#' recompute the deviance or Pearson statistic. This is a conditional,
#' model-based goodness-of-fit check, not a test of the correctness of
#' the fitted sampling family. The tail p-value uses an add-one correction.
#' Refits that fail are excluded and reported.
#'
#' @param model A supported, unweighted binomial, Poisson or
#'   MASS negative-binomial regression fit.
#' @param n Number of bootstrap replicates.
#' @param statistic One of "deviance", "pearson", or "zeros".
#'   "zeros" counts zero responses and is available only for unweighted
#'   Poisson and negative-binomial fits without transformed responses.
#' @param seed Optional seed, preserving the calling session's RNG state.
#' @param workers Number of refitting processes.
#' @return An object of class pb_gof with statistic, observed, reference,
#'   p_value, n, failed, warned, model, seed and call.
#' @examples
#' fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
#' pb_gof(fit, n = 30, seed = 1)
#' @export
pb_gof <- function(model, n = 1000, statistic = c("deviance", "pearson", "zeros"),
                   seed = NULL, workers = 1L) {
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
  p_value <- (1 + sum(valid >= observed)) / (1 + length(valid))
  structure(list(statistic = statistic, observed = observed, reference = reference,
                 p_value = p_value, n = n, failed = failed, warned = warned,
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
