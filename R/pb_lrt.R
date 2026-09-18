#' Parametric bootstrap likelihood-ratio test for nested models
#'
#' Tests a null model against a larger alternative with the likelihood-ratio
#' statistic, using the parametric bootstrap instead of the chi-squared
#' approximation to obtain its null distribution.
#'
#' @details
#' The statistic is \eqn{T = 2(\ell_1 - \ell_0)}, twice the difference between
#' the maximised log-likelihoods of `alternative` and `null`. Its null
#' distribution is estimated by simulating `n` responses from the fitted
#' `null` model, refitting *both* models to each of them and recomputing
#' \eqn{T}. Three p-values are reported:
#'
#' * `"chisq"`: the usual asymptotic p-value, from a chi-squared distribution
#'   with `df` degrees of freedom;
#' * `"bartlett"`: the same, after rescaling \eqn{T} by `df` divided by the
#'   bootstrap mean of the statistic (an empirical Bartlett correction). It
#'   repairs the scale of the chi-squared approximation but not its shape, so
#'   it is no more reliable than `"chisq"` in boundary problems;
#' * `"bootstrap"`: \eqn{(1 + \#\{T^*_b \ge T\}) / (1 + B)}, where \eqn{B} is
#'   the number of valid replicates. It makes no distributional assumption
#'   and can never be smaller than \eqn{1 / (1 + B)}.
#'
#' The chi-squared approximation is poor in small samples, where it usually
#' gives p-values that are too small, and it fails altogether when the null
#' hypothesis puts a parameter on the boundary of its space. The standard
#' example is testing whether a variance component is zero: the statistic is
#' then exactly zero in a large share of samples and the asymptotic p-value is
#' roughly twice what it should be.
#'
#' The models may be of different classes as long as their log-likelihoods are
#' comparable, so a random intercept can be tested with an `lm()` or `glm()`
#' fit as the null and an `lmer()` or `glmer()` fit as the alternative. Mixed
#' models fitted by REML are refitted by maximum likelihood first, with a
#' message. For `coxph` models the partial likelihood is used, the null may be
#' the model without covariates, `Surv(time, status) ~ 1`, and both models
#' must be stratified in the same way.
#'
#' Whether the models are nested cannot be checked in general; it is only
#' verified that they were fitted to the same response, that `alternative`
#' has more parameters and that the observed statistic is not negative.
#' A replicate in which a refit fails, or in which the statistic is negative
#' (the alternative converged to a worse optimum than the null), is dropped.
#'
#' @param null,alternative Fitted models supported by [pb_simulate()], with
#'   `null` nested in `alternative`.
#' @param n Number of bootstrap replicates. Use at least 1000 for p-values
#'   near conventional significance levels.
#' @param ... For `pb_lrt()`, additional arguments used when refitting both
#'   models; see [pb_simulate()]. Unused by `print()`.
#' @param seed Optional single number making the test reproducible; see
#'   [pb_simulate()].
#' @param workers Number of parallel worker processes; see [pb_parallel()].
#'
#' @return An object of class `pb_lrt`: a list with elements
#' \describe{
#'   \item{`statistic`, `df`}{the observed likelihood-ratio statistic and its
#'     degrees of freedom.}
#'   \item{`table`}{data frame with one row per test (`"chisq"`, `"bartlett"`,
#'     `"bootstrap"`) and columns `test`, `statistic`, `df` and `p_value`.}
#'   \item{`reference`}{the `n` bootstrap statistics, `NA` for dropped
#'     replicates.}
#'   \item{`null`, `alternative`}{the two models, refitted by maximum
#'     likelihood if necessary.}
#'   \item{`n`, `failed`, `warned`, `seed`, `call`}{bookkeeping, as for
#'     [pb_simulate()].}
#' }
#' Use [pb_plot_lrt()] to compare the bootstrap null distribution with the
#' chi-squared approximation.
#'
#' @references
#' Davison, A. C. and Hinkley, D. V. (1997) *Bootstrap Methods and their
#' Application*, chapter 4. Cambridge University Press.
#'
#' Halekoh, U. and Hojsgaard, S. (2014) A Kenward-Roger approximation and
#' parametric bootstrap methods for tests in linear mixed models: the R
#' package pbkrtest. *Journal of Statistical Software*, **59**(9), 1-32.
#' \doi{10.18637/jss.v059.i09}
#'
#' @seealso [pb_compare_models()] for comparing models that are not nested.
#'
#' @examples
#' # Does the effect of dose differ between the sexes? (Collett, 1991)
#' budworm <- data.frame(
#'   sex = rep(c("M", "F"), each = 6),
#'   dose = rep(c(1, 2, 4, 8, 16, 32), times = 2),
#'   dead = c(1, 4, 9, 13, 18, 20, 0, 2, 6, 10, 12, 16),
#'   n = 20
#' )
#' common <- glm(cbind(dead, n - dead) ~ sex + log2(dose), data = budworm, family = binomial())
#' separate <- update(common, . ~ sex * log2(dose))
#'
#' test <- pb_lrt(common, separate, n = 200, seed = 1)
#' test
#' test$table
#' @export
pb_lrt <- function(null, alternative, n = 1000, ..., seed = NULL, workers = 1) {
  call <- match.call()
  types <- c(pb_model_type(null), pb_model_type(alternative))
  n <- pb_check_count(n, "n")
  workers <- pb_check_count(workers, "workers")
  pb_check_seed(seed)
  if (sum(types == "coxph") == 1L) {
    pb_abort("A 'coxph' model can only be compared with another 'coxph' model.")
  }

  models <- pb_as_ml(list(null, alternative))
  null <- models[[1]]
  alternative <- models[[2]]
  if (!isTRUE(all.equal(pb_response(null), pb_response(alternative)))) {
    pb_abort(
      "`null` and `alternative` must be fitted to the same observations ",
      "of the same response."
    )
  }

  if (types[1] == "coxph") {
    strata <- lapply(models, function(m) as.character(pb_coxph_strata(m)))
    if (!identical(strata[[1]], strata[[2]])) {
      pb_abort(
        "`null` and `alternative` must be stratified in the same way: partial ",
        "likelihoods based on different strata are not comparable."
      )
    }
  }

  loglik <- list(stats::logLik(null), stats::logLik(alternative))
  if (!all(is.finite(unlist(loglik)))) {
    pb_abort(
      "The log-likelihood of a model is not available, ",
      "as happens for quasi-likelihood families."
    )
  }
  df <- attr(loglik[[2]], "df") - attr(loglik[[1]], "df")
  if (df < 1) {
    pb_abort("`alternative` must have more parameters than `null`. Are the arguments swapped?")
  }
  statistic <- 2 * (as.numeric(loglik[[2]]) - as.numeric(loglik[[1]]))
  if (statistic < -pb_lrt_tol) {
    pb_abort(
      "The likelihood-ratio statistic is negative (", format(statistic, digits = 3),
      "), so `null` does not appear to be nested in `alternative`."
    )
  }
  statistic <- max(statistic, 0)

  responses <- pb_with_seed(seed, pb_sim_response(null, types[1], n))
  aux <- lapply(1:2, function(i) if (types[i] != "merMod") pb_refit_data(models[[i]]))
  out <- pb_lapply(
    responses, pb_lrt_one,
    models = models, types = types, aux = aux, dots = list(...),
    workers = workers
  )

  failed <- vapply(out, function(o) !is.null(o$error), logical(1))
  warned <- vapply(out, function(o) o$warned, logical(1))
  if (all(failed)) {
    pb_abort("All ", n, " bootstrap refits failed. First error: ", out[[1]]$error)
  }
  pb_warn_replicates(failed, warned, out)

  reference <- rep(NA_real_, n)
  reference[!failed] <- pmax(vapply(out[!failed], function(o) o$statistic, numeric(1)), 0)
  valid <- reference[!failed]
  bartlett <- statistic * df / mean(valid)

  table <- data.frame(
    test = c("chisq", "bartlett", "bootstrap"),
    statistic = c(statistic, bartlett, statistic),
    df = c(df, df, NA),
    p_value = c(
      stats::pchisq(statistic, df, lower.tail = FALSE),
      stats::pchisq(bartlett, df, lower.tail = FALSE),
      (1 + sum(valid >= statistic)) / (1 + length(valid))
    ),
    stringsAsFactors = FALSE
  )

  structure(
    list(
      statistic = statistic,
      df = df,
      table = table,
      reference = reference,
      null = null,
      alternative = alternative,
      n = n,
      failed = failed,
      warned = warned,
      seed = seed,
      call = call
    ),
    class = "pb_lrt"
  )
}

# Optimiser noise makes a statistic that should be zero come out as about
# -1e-13; anything clearly below zero is a failed optimisation.
pb_lrt_tol <- 1e-6

# Refit both models to one response simulated from the null model.
pb_lrt_one <- function(response, models, types, aux, dots) {
  out <- pb_safely(function() {
    loglik <- vapply(1:2, function(i) {
      as.numeric(stats::logLik(pb_refit(models[[i]], types[i], response, aux[[i]], dots)))
    }, numeric(1))
    statistic <- 2 * (loglik[2] - loglik[1])
    if (!is.finite(statistic) || statistic < -pb_lrt_tol) {
      stop(
        "negative or undefined likelihood-ratio statistic (",
        format(statistic, digits = 3), ")"
      )
    }
    statistic
  })
  list(statistic = out$value, warned = out$warned, error = out$error)
}

# Likelihood-ratio tests need maximum likelihood, not REML, fits.
pb_as_ml <- function(models) {
  reml <- vapply(models, function(m) inherits(m, "merMod") && lme4::isREML(m), logical(1))
  if (any(reml)) {
    message("Refitting REML fits by maximum likelihood, as likelihood-ratio tests require.")
    models[reml] <- lapply(models[reml], lme4::refitML)
  }
  models
}

# The response a model was fitted to, as a plain numeric vector.
pb_response <- function(model) {
  if (inherits(model, "coxph")) {
    y <- model[["y"]]
  } else {
    y <- stats::model.response(stats::model.frame(model))
  }
  if (is.factor(y)) {
    y <- as.integer(y)
  }
  as.numeric(unclass(y))
}

pb_formula_label <- function(model) {
  paste(trimws(deparse(stats::formula(model), width.cutoff = 500L)), collapse = " ")
}

#' @rdname pb_lrt
#' @param x A `pb_lrt` object.
#' @param digits Number of significant digits to print.
#' @export
print.pb_lrt <- function(x, digits = 3, ...) {
  replicates <- as.character(x$n)
  if (any(x$failed)) {
    replicates <- paste0(replicates, " (", sum(x$failed), " dropped)")
  }
  labels <- c(
    chisq = "Chi-squared (asymptotic)",
    bartlett = "Bartlett-corrected",
    bootstrap = "Parametric bootstrap"
  )

  cat("<pb_lrt> Parametric bootstrap likelihood-ratio test\n")
  cat("  Null:        ", pb_formula_label(x$null), "\n", sep = "")
  cat("  Alternative: ", pb_formula_label(x$alternative), "\n", sep = "")
  cat("  Replicates:  ", replicates, "\n", sep = "")
  cat("  Statistic:   ", format(x$statistic, digits = digits), " on ", x$df, " df\n\n", sep = "")

  # The bootstrap p-value cannot be smaller than 1 / (1 + B), so it is
  # printed as it is; only the asymptotic ones can be vanishingly small.
  bootstrap <- x$table$test == "bootstrap"
  p_values <- format.pval(x$table$p_value, digits = digits)
  p_values[bootstrap] <- format(x$table$p_value[bootstrap], digits = digits)
  out <- data.frame(p.value = p_values, row.names = labels[x$table$test])
  print(out)
  invisible(x)
}
