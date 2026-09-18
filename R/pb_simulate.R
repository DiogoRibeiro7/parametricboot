#' Run parametric bootstrap replicates
#'
#' Simulates `n` new responses from a fitted model, refits the model to each
#' of them and collects the resulting coefficient estimates and standard
#' errors.
#'
#' @details
#' Each replicate draws a response from the fitted model and refits the model
#' to it, holding the covariates fixed.
#'
#' * For `lm` and `glm` models the response is drawn with [stats::simulate()]
#'   and the original call is re-evaluated on the original data, so
#'   transformed terms (`log(x)`, `poly(x, 2)`), `offset()`, `weights`,
#'   `subset` and two-column binomial responses are all supported. The model
#'   must have been fitted with a `data` argument.
#' * For `lmer` and `glmer` models the response is drawn with the 'lme4'
#'   `simulate()` method (new random effects are drawn for every replicate)
#'   and the model is refitted with [lme4::refit()], exactly as
#'   [lme4::bootMer()] does. Besides the fixed effects, the variance
#'   components are tracked: the random-effect standard deviations and
#'   correlations and, if the family has one, the residual standard deviation.
#'   They are named as in `confint(model, oldNames = FALSE)`, for example
#'   `sd_(Intercept)|Subject`, `cor_Days.(Intercept)|Subject` and `sigma`.
#'   'lme4' provides no standard errors for them, so summaries that need one
#'   (the Wald `coverage` and studentised intervals) are `NA` for these rows.
#' * For `coxph` models there is no fully parametric model to simulate from, so
#'   the model-based resampling scheme of Davison and Hinkley (1997,
#'   Algorithm 7.3) is used: failure times are drawn from the fitted survivor
#'   function based on the Breslow baseline hazard, and censoring times from
#'   the Kaplan-Meier estimate of the censoring distribution, conditional on
#'   the observed censoring pattern. In a model with `strata()`, each stratum
#'   has its own baseline hazard, censoring distribution and end of follow-up.
#'   Only right-censored, unweighted models are supported, without `tt()`,
#'   penalised or `frailty()` terms, strata-by-covariate interactions or
#'   `cluster()` (the observations are resampled independently).
#'
#' A refit that throws an error is recorded as failed and dropped from all
#' summaries; a single warning reports how many refits failed or produced
#' warnings (for example convergence problems). Replicates with warnings are
#' kept; see [pb_drop_warned()] for when and how to remove them.
#'
#' @param model A fitted model from [stats::lm()], [stats::glm()],
#'   [lme4::lmer()], [lme4::glmer()] or [survival::coxph()].
#' @param n Number of bootstrap replicates.
#' @param ... Additional arguments used when refitting: they override
#'   arguments of the original call for `lm`, `glm` and `coxph` models, and are
#'   passed to [lme4::refit()] for mixed models.
#' @param seed Optional single number. If supplied, the replicates are
#'   reproducible and the state of the global random number generator is left
#'   untouched.
#' @param keep_fits Should the refitted models be stored? They are needed by
#'   [pb_predict_boot()], [pb_plot_predictions()] and [pb_compare_models()],
#'   but can use a lot of memory for large `n`.
#'
#' @return An object of class `pb_boot`: a list with elements
#' \describe{
#'   \item{`original`}{the fitted model.}
#'   \item{`replicates`}{list of `n` refitted models (`NULL` for failed
#'     refits), or `NULL` if `keep_fits = FALSE`.}
#'   \item{`estimates`, `std_errors`}{`n` by `p` matrices of parameter
#'     estimates and their standard errors. For mixed models the parameters
#'     are the fixed effects followed by the variance components, whose
#'     standard errors are `NA`.}
#'   \item{`failed`}{logical vector flagging the replicates that are excluded
#'     from all summaries: refits that threw an error, and replicates removed
#'     by [pb_drop_warned()].}
#'   \item{`warned`}{logical vector flagging the refits that produced
#'     warnings.}
#'   \item{`n`, `seed`, `call`}{the number of replicates, the seed and the
#'     call.}
#' }
#'
#' @references
#' Davison, A. C. and Hinkley, D. V. (1997) *Bootstrap Methods and their
#' Application*. Cambridge University Press.
#'
#' @seealso [pb_parallel()] to run the refits on several cores;
#'   [pb_summary_table()], [pb_confint()] and [pb_plot_estimates()] to
#'   summarise the result.
#'
#' @examples
#' fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
#' res <- pb_simulate(fit, n = 50, seed = 1)
#' res
#'
#' pb_summary_table(res)
#' @export
pb_simulate <- function(model, n = 100, ..., seed = NULL, keep_fits = TRUE) {
  pb_run(
    model,
    n = n, dots = list(...), seed = seed, keep_fits = keep_fits,
    workers = 1L, call = match.call()
  )
}
