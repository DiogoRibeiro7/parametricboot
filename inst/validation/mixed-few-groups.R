# Small-group Gaussian random-intercept coverage experiment.
# Run after installing parametricboot and lme4:
# Rscript inst/validation/mixed-few-groups.R
# OUTER_N=100 BOOT_N=399 Rscript inst/validation/mixed-few-groups.R
#
# Each outer draw regenerates random intercepts and residual noise. Bootstrap
# draws are marginal (new random effects), as in lme4::bootMer(use.u = FALSE).

if (!requireNamespace("parametricboot", quietly = TRUE) ||
    !requireNamespace("lme4", quietly = TRUE) ||
    !requireNamespace("withr", quietly = TRUE)) {
  stop("Install parametricboot, lme4 and withr.")
}

read_count <- function(key, default) {
  raw <- Sys.getenv(key, unset = as.character(default))
  value <- suppressWarnings(as.integer(raw))
  if (length(value) != 1L || is.na(value) || value < 2L ||
      !identical(as.character(value), raw)) {
    stop(sprintf("%s must be an integer >= 2.", key))
  }
  value
}

outer_n <- read_count("OUTER_N", 30L)
boot_n <- read_count("BOOT_N", 99L)
groups <- 6L
per_group <- 8L
true_slope <- 0.6
group_sd <- 0.8
residual_sd <- 1.0

# Within each group, x varies independently of its intercept.
group <- factor(rep(seq_len(groups), each = per_group))
x <- rep(seq(-1, 1, length.out = per_group), groups)
design <- data.frame(group = group, x = x)

experiment <- withr::with_seed(2061L, {
  covered <- matrix(NA, nrow = outer_n, ncol = 2L,
                    dimnames = list(NULL, c("wald", "percentile")))
  warned <- integer(outer_n)
  failed <- integer(outer_n)
  singular <- logical(outer_n)
  outer_errors <- logical(outer_n)
  for (i in seq_len(outer_n)) {
    intercepts <- stats::rnorm(groups, sd = group_sd)
    y <- 1 + true_slope * x + intercepts[as.integer(group)] +
      stats::rnorm(length(x), sd = residual_sd)
    dat <- transform(design, y = y)
    fit <- tryCatch(suppressWarnings(lme4::lmer(
      y ~ x + (1 | group), data = dat, REML = FALSE
    )), error = function(e) NULL)
    if (is.null(fit)) {
      outer_errors[i] <- TRUE
      next
    }
    singular[i] <- lme4::isSingular(fit)
    coef_table <- summary(fit)$coefficients
    estimate <- coef_table["x", "Estimate"]
    std_error <- coef_table["x", "Std. Error"]
    if (is.finite(estimate) && is.finite(std_error) && std_error > 0) {
      # Normal Wald approximation, not a small-sample exact interval.
      bounds <- estimate + c(-1, 1) * stats::qnorm(0.975) * std_error
      covered[i, "wald"] <- bounds[1] <= true_slope &&
        true_slope <= bounds[2]
    }
    boot <- tryCatch(suppressWarnings(parametricboot::pb_simulate(
      fit, n = boot_n, seed = i, keep_fits = FALSE
    )), error = function(e) NULL)
    if (is.null(boot)) next
    failed[i] <- sum(boot$failed)
    warned[i] <- sum(boot$warned)
    if (sum(!boot$failed) < 2L) next
    limits <- tryCatch(suppressWarnings(parametricboot::pb_confint(
      boot, type = "percentile", level = 0.95
    )), error = function(e) NULL)
    if (is.null(limits)) next
    row <- limits[limits$term == "x", , drop = FALSE]
    if (nrow(row) == 1L && is.finite(row$lower) &&
        is.finite(row$upper)) {
      covered[i, "percentile"] <- row$lower <= true_slope &&
        true_slope <= row$upper
    }
  }
  list(covered = covered, warned = warned, failed = failed,
       singular = singular, outer_errors = outer_errors)
})

out <- do.call(rbind, lapply(colnames(experiment$covered), function(method) {
  indicators <- experiment$covered[, method]
  valid <- !is.na(indicators)
  evaluable <- sum(valid)
  successes <- sum(indicators[valid])
  estimate <- if (evaluable > 0L) successes / evaluable else NA_real_
  data.frame(
    method = method, outer_total = outer_n, evaluable = evaluable,
    covered = successes, conditional_coverage = estimate,
    outer_mc_se = if (evaluable > 0L) {
      sqrt(estimate * (1 - estimate) / evaluable)
    } else NA_real_
  )
}))
print(out, row.names = FALSE, digits = 4)
cat("Singular original fits:", sum(experiment$singular), "\n")
cat("Original fit errors:", sum(experiment$outer_errors), "\n")
cat("Warned bootstrap refits:", sum(experiment$warned),
    "; failed bootstrap refits:", sum(experiment$failed), "\n")
cat("Results are conditional on interval evaluability.\n")
cat("Neither Wald nor percentile intervals are guaranteed nominal coverage.\n")
