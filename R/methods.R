#' Methods for `pb_boot` objects
#'
#' `print()` gives a short overview of a parametric bootstrap, `summary()`
#' returns the table of [pb_summary_table()], and `confint()` returns the
#' intervals of [pb_confint()] in the matrix layout used by
#' [stats::confint()].
#'
#' @param x,object A `pb_boot` object from [pb_simulate()] or [pb_parallel()].
#' @param parm Names of the coefficients to return intervals for. Defaults to
#'   all coefficients.
#' @param level Confidence level, strictly between 0 and 1.
#' @param type Type of interval; see [pb_confint()].
#' @param ... For `summary()`, arguments passed to [pb_summary_table()];
#'   otherwise unused.
#'
#' @return `print()` returns `x` invisibly. `summary()` returns a data frame.
#'   `confint()` returns a matrix with one row per coefficient and columns
#'   giving the lower and upper limits.
#'
#' @examples
#' fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
#' res <- pb_simulate(fit, n = 50, seed = 1)
#'
#' print(res)
#' summary(res)
#' confint(res, level = 0.9)
#' @name pb_boot-methods
NULL

#' @rdname pb_boot-methods
#' @export
print.pb_boot <- function(x, ...) {
  model <- class(x$original)[1]
  family <- tryCatch(stats::family(x$original)$family, error = function(e) NULL)
  if (!is.null(family)) {
    model <- paste0(model, " (", family, ")")
  }

  replicates <- as.character(x$n)
  notes <- c(
    if (any(x$failed)) paste(sum(x$failed), "dropped"),
    if (any(x$warned & !x$failed)) paste(sum(x$warned & !x$failed), "with warnings")
  )
  if (length(notes) > 0L) {
    replicates <- paste0(replicates, " (", paste(notes, collapse = ", "), ")")
  }

  cat("<pb_boot> Parametric bootstrap\n")
  cat("  Model:      ", model, "\n", sep = "")
  cat("  Replicates: ", replicates, "\n", sep = "")
  cat("  Terms:      ", paste(colnames(x$estimates), collapse = ", "), "\n", sep = "")
  if (is.null(x$replicates)) {
    cat("  Refitted models were not kept (`keep_fits = FALSE`).\n")
  }
  invisible(x)
}

#' @rdname pb_boot-methods
#' @export
summary.pb_boot <- function(object, ...) {
  pb_summary_table(object, ...)
}

#' @rdname pb_boot-methods
#' @importFrom stats confint
#' @export
confint.pb_boot <- function(object, parm, level = 0.95,
                            type = c("percentile", "basic", "normal"), ...) {
  ci <- pb_confint(object, level = level, type = type)
  alpha <- (1 - level) / 2
  out <- as.matrix(ci[c("lower", "upper")])
  dimnames(out) <- list(ci$term, paste(format(100 * c(alpha, 1 - alpha), trim = TRUE), "%"))
  if (!missing(parm)) {
    out <- out[pb_check_terms(object, parm), , drop = FALSE]
  }
  out
}
