#' Predict with bootstrap uncertainty
#'
#' Computes predictions from every refitted bootstrap model. When
#' `pb_simulate()` or `pb_parallel()` was run with `newdata`, the stored
#' numeric predictions are available even when `keep_fits = FALSE`.
#' Calling without `newdata` or `...` retrieves that cache. To supply
#' `newdata` and arguments explicitly, they must match the saved dataset
#' and `predict_args` exactly; otherwise a cached-only result refuses to
#' return potentially mismatched predictions. With retained fits, a
#' nonmatching request is recomputed from those fits.
#'
#' @inheritParams pb_confint
#' @param newdata Optional data frame to predict for. If `NULL`, predictions
#'   are made for the observations used to fit the model.
#' @param ... Additional arguments passed to [stats::predict()], such as
#'   `type = "response"`, or `re.form = NA` for population-level predictions
#'   from mixed models.
#'
#' @return A numeric matrix with one row per observation and one column per
#'   successful bootstrap replicate.
#'
#' @examples
#' fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
#' res <- pb_simulate(fit, n = 50, seed = 1)
#'
#' new_cars <- data.frame(mpg = c(15, 20, 25))
#' preds <- pb_predict_boot(res, new_cars, type = "response")
#' dim(preds)
#'
#' # 95% percentile intervals for the predicted probabilities
#' t(apply(preds, 1, quantile, probs = c(0.025, 0.975)))
#' @export
pb_predict_boot <- function(results, newdata = NULL, ...) {
  pb_check_boot(results)
  if (!is.null(newdata) && !is.data.frame(newdata)) {
    pb_abort("`newdata` must be a data frame or `NULL`.")
  }
  args <- list(...)
  if (!is.null(results$predictions)) {
    requested_cache <- is.null(newdata) && !length(args)
    explicit_match <- identical(newdata, results$prediction_data) &&
      identical(args, results$prediction_args)
    if (requested_cache || explicit_match) {
      selected <- !results$failed & !results$prediction_failed
      if (!any(selected)) {
        pb_abort("No successful cached predictions remain.")
      }
      return(results$predictions[, selected, drop = FALSE])
    }
    if (is.null(results$replicates)) {
      pb_abort(paste0(
        "Stored predictions were calculated for different `newdata` or ",
        "prediction arguments. Repeat the bootstrap with matching ",
        "`newdata` and `predict_args`, or set `keep_fits = TRUE`."
      ))
    }
  }
  fits <- pb_fits(results)
  preds <- lapply(fits, function(fit) {
    if (is.null(newdata)) {
      stats::predict(fit, ...)
    } else {
      stats::predict(fit, newdata = newdata, ...)
    }
  })
  # Do not silently flatten interval/matrix predictions or recycle vectors
  # whose lengths differ across refits. The public API returns one numeric
  # scalar per observation and per successful bootstrap replicate.
  expected_rows <- if (!is.null(newdata)) nrow(newdata) else length(preds[[1L]])
  valid <- vapply(preds, function(value) {
    is.numeric(value) && is.null(dim(value)) &&
      length(value) == expected_rows && all(is.finite(value))
  }, logical(1))
  if (!all(valid)) {
    pb_abort(paste0(
      "Each bootstrap prediction must be a finite numeric vector with ",
      "one value per observation and identical length across refits."
    ))
  }
  matrix_values <- matrix(
    unlist(preds, use.names = FALSE),
    nrow = expected_rows, ncol = length(preds)
  )
  # Preserve names supplied by predict(), as the old cbind path did.
  if (!is.null(names(preds[[1L]]))) {
    rownames(matrix_values) <- names(preds[[1L]])
  }
  matrix_values
}

# A single finite numeric prediction per requested row is required for the
# lightweight cached result. Matrix/interval/survival-curve predictions are
# intentionally not silently flattened into a different statistical object.
pb_predict_one <- function(fit, newdata, predict_args = list()) {
  values <- do.call(stats::predict,
                    c(list(object = fit, newdata = newdata), predict_args))
  if (!is.numeric(values) || !is.null(dim(values)) ||
      length(values) != nrow(newdata) || any(!is.finite(values))) {
    pb_abort(paste0(
      "Cached predict() must return a finite numeric vector with ",
      "one value per row of `newdata`."
    ))
  }
  unname(as.numeric(values))
}
