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
  if (!inherits(model, c("glm", "glmerMod", "coxph"))) {
    stop("model must be fitted with glm, glmer, or coxph")
  }

  data <- model.frame(model)
  resp <- all.vars(formula(model))[1]

  sims <- replicate(n, {
    y <- stats::simulate(model, nsim = 1)[[1]]
    data[[resp]] <- y
    stats::update(model, data = data, ...)
  }, simplify = FALSE)

  structure(list(original = model, replicates = sims), class = "pb_boot")
}
