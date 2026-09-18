#' Drop replicates whose refit raised a warning
#'
#' Marks the bootstrap replicates whose refit produced a warning as dropped,
#' so that they are excluded from all summaries, plots and predictions.
#'
#' @details
#' The typical use is logistic regression on small samples, where some
#' simulated data sets are perfectly separated. The maximum likelihood estimate
#' does not exist for such data: `glm()` warns that fitted probabilities of 0
#' or 1 occurred and returns arbitrary, very large coefficients. A handful of
#' these replicates is enough to ruin bootstrap means, standard errors and
#' histograms.
#'
#' Dropping them changes the question being answered: the summaries then
#' describe the estimator *conditional on the fit being well behaved*. Report
#' the proportion of dropped replicates alongside the results. Percentile
#' intervals from [pb_confint()] are barely affected by a few extreme
#' replicates and do not need this treatment.
#'
#' Not every warning signals a useless fit (for mixed models, convergence
#' warnings are often false alarms), so replicates are never dropped
#' automatically. Inspect `results$warned` and the affected
#' `results$replicates` before deciding.
#'
#' @inheritParams pb_confint
#'
#' @return A `pb_boot` object in which the replicates that raised warnings are
#'   flagged in `failed`, and their estimates, standard errors and refitted
#'   models are removed.
#'
#' @examples
#' # About 1% of data sets simulated from this model are perfectly separated
#' fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
#' res <- suppressWarnings(pb_simulate(fit, n = 300, seed = 2025))
#' sum(res$warned)
#'
#' pb_key_stats(res)[c("term", "bias", "std_error")]
#' pb_key_stats(pb_drop_warned(res))[c("term", "bias", "std_error")]
#' @export
pb_drop_warned <- function(results) {
  pb_check_boot(results)
  if (all(results$failed | results$warned)) {
    pb_abort("Every replicate failed or raised a warning, so none would be left.")
  }

  drop <- results$warned & !results$failed
  results$failed[drop] <- TRUE
  results$estimates[drop, ] <- NA_real_
  results$std_errors[drop, ] <- NA_real_
  if (!is.null(results$replicates)) {
    results$replicates[drop] <- list(NULL)
  }
  results
}
