# Internal helpers -------------------------------------------------------------

pb_abort <- function(...) {
  stop(..., call. = FALSE)
}

# Only invalid caller arguments use this permanent error classification.
# Operational failures (including individual refit failures) still use
# pb_abort() and retain their existing retry/aggregation semantics.
pb_abort_validation <- function(...) {
  stop(dataexcept::new_dataexcept_error(
    message = paste0(..., collapse = ""),
    type = "ValidationError",
    class = "parametricboot_validation_error"
  ))
}

pb_require <- function(pkg, reason) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    pb_abort("Package '", pkg, "' is required to ", reason, ". Please install it.")
  }
  invisible(TRUE)
}

pb_check_boot <- function(results) {
  if (!inherits(results, "pb_boot")) {
    pb_abort_validation("`results` must be a 'pb_boot' object created by `pb_simulate()` or `pb_parallel()`.")
  }
  invisible(results)
}

pb_check_count <- function(x, arg) {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) || x < 1 || x != round(x)) {
    pb_abort_validation("`", arg, "` must be a single positive whole number.")
  }
  as.integer(x)
}

pb_check_seed <- function(seed) {
  if (!is.null(seed) && (!is.numeric(seed) || length(seed) != 1L || is.na(seed))) {
    pb_abort_validation("`seed` must be `NULL` or a single number.")
  }
  invisible(seed)
}

pb_check_level <- function(level) {
  if (!is.numeric(level) || length(level) != 1L || is.na(level) || level <= 0 || level >= 1) {
    pb_abort_validation("`level` must be a single number strictly between 0 and 1.")
  }
  level
}

pb_check_terms <- function(results, parameter) {
  terms <- colnames(results$estimates)
  if (is.null(parameter)) {
    return(terms)
  }
  unknown <- setdiff(parameter, terms)
  if (!is.character(parameter) || length(unknown) > 0L) {
    pb_abort_validation(
      "Unknown parameter(s): ", paste(unknown, collapse = ", "),
      ". Available: ", paste(terms, collapse = ", "), "."
    )
  }
  parameter
}

pb_with_seed <- function(seed, code) {
  if (is.null(seed)) {
    code
  } else {
    withr::with_seed(seed, code)
  }
}

# Parameters of a fitted model that are tracked across replicates: the
# coefficients, followed for mixed models by the variance components.
pb_coef <- function(fit) {
  if (inherits(fit, "merMod")) {
    c(lme4::fixef(fit), pb_ran_pars(fit))
  } else {
    stats::coef(fit)
  }
}

# Random-effect standard deviations and correlations, and the residual
# standard deviation if the family has one, named as 'lme4' names them in
# `confint(fit, oldNames = FALSE)`.
pb_ran_pars <- function(fit) {
  vc <- as.data.frame(lme4::VarCorr(fit))
  labels <- ifelse(
    is.na(vc$var2),
    paste0("sd_", vc$var1, "|", vc$grp),
    paste0("cor_", vc$var2, ".", vc$var1, "|", vc$grp)
  )
  labels[vc$grp == "Residual" & is.na(vc$var1)] <- "sigma"
  stats::setNames(vc$sdcor, labels)
}

# Standard errors aligned with `pb_coef()`. Aliased coefficients and variance
# components, for which the fit provides no standard error, give `NA`.
pb_se <- function(fit) {
  co <- pb_coef(fit)
  se <- stats::setNames(rep(NA_real_, length(co)), names(co))
  v <- sqrt(diag(as.matrix(stats::vcov(fit))))
  common <- intersect(names(se), names(v))
  se[common] <- v[common]
  se
}

# Named finite numeric statistics are required to keep a stable matrix layout.
pb_eval_statistic <- function(statistic, fit, expected_names = NULL) {
  x <- statistic(fit)
  valid <- is.numeric(x) && is.null(dim(x)) && !is.object(x) &&
    length(x) > 0L && !is.null(names(x)) &&
    !anyNA(names(x)) && all(nzchar(names(x))) &&
    !anyDuplicated(names(x)) && all(is.finite(x))
  if (!valid || (!is.null(expected_names) && !identical(names(x), expected_names))) {
    pb_abort_validation("`statistic` must return a finite named numeric vector with consistent names and order.")
  }
  x
}

pb_reference_estimate <- function(results) {
  if (is.null(results$statistic_estimate)) pb_coef(results$original) else results$statistic_estimate
}

# Bootstrap estimates of the successful replicates only.
pb_estimates <- function(results) {
  results$estimates[!results$failed, , drop = FALSE]
}

# Fitted replicate models of the successful replicates only.
pb_fits <- function(results) {
  if (is.null(results$replicates)) {
    pb_abort(
      "`results` does not contain the refitted models. ",
      "Re-run `pb_simulate()` with `keep_fits = TRUE`."
    )
  }
  results$replicates[!results$failed]
}
