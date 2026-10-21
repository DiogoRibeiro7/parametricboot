# Repeated-sampling Cox regression coverage under independent censoring.
# Rscript inst/validation/survival-coverage.R
# OUTER_N=150 BOOT_N=399 Rscript inst/validation/survival-coverage.R
#
# Here the population generating law is exponential proportional hazards.
# Parametricboot uses a Cox model-based bootstrap with estimated baseline
# hazard and censoring distribution, not this known parametric law.

if (!requireNamespace("parametricboot", quietly = TRUE) ||
    !requireNamespace("survival", quietly = TRUE) ||
    !requireNamespace("withr", quietly = TRUE)) {
  stop("Install parametricboot, survival and withr.")
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

outer_n <- read_count("OUTER_N", 40L)
boot_n <- read_count("BOOT_N", 99L)
n_people <- 120L
true_log_hazard_ratio <- log(1.8)
baseline_rate <- 0.12
censor_rate <- 0.08
level <- 0.95

experiment <- withr::with_seed(3040L, {
  covered <- matrix(NA, nrow = outer_n, ncol = 2L,
                    dimnames = list(NULL, c("wald", "percentile")))
  original_errors <- logical(outer_n)
  bootstrap_errors <- logical(outer_n)
  inner_warned <- inner_failed <- integer(outer_n)
  censor_fraction <- rep(NA_real_, outer_n)
  for (i in seq_len(outer_n)) {
    x <- stats::rbinom(n_people, size = 1L, prob = 0.5)
    event <- stats::rexp(
      n_people, rate = baseline_rate * exp(true_log_hazard_ratio * x)
    )
    censor <- stats::rexp(n_people, rate = censor_rate)
    time <- pmin(event, censor)
    status <- as.integer(event <= censor)
    censor_fraction[i] <- mean(status == 0L)
    dat <- data.frame(time = time, status = status, x = x)
    fit <- tryCatch(suppressWarnings(survival::coxph(
      survival::Surv(time, status) ~ x, data = dat
    )), error = function(e) NULL)
    if (is.null(fit) || any(!is.finite(stats::coef(fit)))) {
      original_errors[i] <- TRUE
      next
    }
    slope <- unname(stats::coef(fit)["x"])
    se <- unname(sqrt(diag(stats::vcov(fit)))["x"])
    if (is.finite(se) && se > 0) {
      ci <- slope + c(-1, 1) * stats::qnorm((1 + level) / 2) * se
      covered[i, "wald"] <- ci[1] <= true_log_hazard_ratio &&
        true_log_hazard_ratio <= ci[2]
    }
    boot <- tryCatch(suppressWarnings(parametricboot::pb_simulate(
      fit, n = boot_n, seed = i, keep_fits = FALSE
    )), error = function(e) NULL)
    if (is.null(boot)) {
      bootstrap_errors[i] <- TRUE
      next
    }
    inner_failed[i] <- sum(boot$failed)
    inner_warned[i] <- sum(boot$warned)
    if (sum(!boot$failed) < 2L) next
    interval <- tryCatch(parametricboot::pb_confint(
      boot, level = level, type = "percentile"
    ), error = function(e) NULL)
    if (is.null(interval)) next
    row <- interval[interval$term == "x", , drop = FALSE]
    if (nrow(row) == 1L && is.finite(row$lower) &&
        is.finite(row$upper)) {
      covered[i, "percentile"] <- row$lower <= true_log_hazard_ratio &&
        true_log_hazard_ratio <= row$upper
    }
  }
  list(covered = covered, original_errors = original_errors,
       bootstrap_errors = bootstrap_errors, inner_warned = inner_warned,
       inner_failed = inner_failed, censor_fraction = censor_fraction)
})
output <- do.call(rbind, lapply(colnames(experiment$covered), function(method) {
  valid <- !is.na(experiment$covered[, method])
  n_valid <- sum(valid)
  hits <- sum(experiment$covered[valid, method])
  probability <- if (n_valid > 0L) hits / n_valid else NA_real_
  data.frame(method = method, total = outer_n, evaluable = n_valid,
             covered = hits, conditional_coverage = probability,
             outer_mc_se = if (n_valid > 0L) {
               sqrt(probability * (1 - probability) / n_valid)
             } else NA_real_)
}))
print(output, row.names = FALSE, digits = 4)
cat("Mean censoring fraction:", mean(experiment$censor_fraction), "\n")
cat("Original fit failures:", sum(experiment$original_errors), "\n")
cat("Bootstrap call failures:", sum(experiment$bootstrap_errors), "\n")
cat("Inner warned/failed refits:", sum(experiment$inner_warned), "/",
    sum(experiment$inner_failed), "\n")
cat("Coverage is conditional on evaluability and excludes inner MC error.\n")
