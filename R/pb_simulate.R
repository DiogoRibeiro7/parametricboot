#' Run parametric bootstrap replicates
#'
#' @param model A fitted model object from `glm`, `glmer`, or `coxph`.
#' @param n Integer, number of bootstrap replicates.
#' @param ... Additional arguments passed to model fitting.
#'
#' @return A list of fitted models from each replicate.
#' @examples
#' # pb_simulate(fit, 100)
#' @export
pb_simulate <- function(model, n = 100, ...) {
  stop("pb_simulate() not yet implemented")
}
