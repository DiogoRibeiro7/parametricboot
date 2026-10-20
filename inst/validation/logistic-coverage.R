# Repeated-sampling coverage study for sparse binary logistic regression.
# Rscript inst/validation/logistic-coverage.R
# Optional environment: OUTER_N=100 BOOT_N=399
# Finite Monte Carlo outputs are descriptive, never coverage guarantees.

if (!requireNamespace("parametricboot", quietly = TRUE) ||
    !requireNamespace("withr", quietly = TRUE)) {
  stop("Install parametricboot and withr before running this script.")
}
read_count <- function(name, default) {
  raw <- Sys.getenv(name, as.character(default))
  value <- suppressWarnings(as.integer(raw))
  if (length(value) != 1L || is.na(value) || value < 2L ||
      !identical(raw, as.character(value))) {
    stop(sprintf("%s must be an integer >= 2.", name))
  }
  value
}

outer_n <- read_count("OUTER_N", 60L)
boot_n <- read_count("BOOT_N", 199L)
truth <- c("(Intercept)" = -0.5, "x" = 1.3)
x <- seq(-2, 2, length.out = 24L)
p <- stats::plogis(truth[1] + truth[2] * x)

# Conditional coverage is reported only for outer datasets with estimable
# finite Wald intervals. Non-estimable samples are counted explicitly.
results <- withr::with_seed(2405L, {
  out <- matrix(NA, nrow = outer_n, ncol = 3L,
                dimnames = list(NULL, c("wald", "percentile", "student")))
  warned <- failed <- integer(outer_n)
  original_warnings <- logical(outer_n)
  for (i in seq_len(outer_n)) {
    y <- stats::rbinom(length(x), size = 1L, prob = p)
    warning_seen <- FALSE
    fit <- withCallingHandlers(
      stats::glm(y ~ x, data = data.frame(y = y, x = x),
                 family = stats::binomial()),
      warning = function(w) {
        warning_seen <<- TRUE
        invokeRestart("muffleWarning")
      }
    )
    original_warnings[i] <- warning_seen
    coef_table <- summary(fit)$coefficients
    slope <- coef_table["x", "Estimate"]
    slope_se <- coef_table["x", "Std. Error"]
    if (warning_seen || !is.finite(slope) ||
        !is.finite(slope_se) || slope_se <= 0) next

    wald <- slope + c(-1, 1) * stats::qnorm(0.975) * slope_se
    out[i, "wald"] <- wald[1] <= truth["x"] && truth["x"] <= wald[2]
    boot <- suppressWarnings(parametricboot::pb_simulate(
      fit, n = boot_n, seed = i, keep_fits = FALSE
    ))
    warned[i] <- sum(boot$warned, na.rm = TRUE)
    failed[i] <- sum(boot$failed, na.rm = TRUE)
    if (sum(!boot$failed) < 2L) next
    for (method in c("percentile", "student")) {
      interval <- tryCatch(
        suppressWarnings(parametricboot::pb_confint(
          boot, level = 0.95, type = method
        )),
        error = function(e) NULL
      )
      if (is.null(interval)) next
      row <- interval[interval$term == "x", , drop = FALSE]
      if (nrow(row) != 1L || !is.finite(row$lower) ||
          !is.finite(row$upper)) next
      out[i, method] <- row$lower <= truth["x"] &&
        truth["x"] <= row$upper
    }
  }
  list(coverage = out, warned = warned, failed = failed,
       original_warnings = original_warnings)
})

# Different methods can have different evaluable denominators.
summary_table <- do.call(rbind, lapply(colnames(results$coverage), function(method) {
  indicator <- results$coverage[, method]
  valid <- !is.na(indicator)
  n_valid <- sum(valid)
  hits <- sum(indicator[valid])
  estimated <- if (n_valid > 0L) hits / n_valid else NA_real_
  data.frame(
    method = method, outer_total = outer_n, evaluable = n_valid,
    covered = hits, coverage_given_evaluable = estimated,
    outer_mc_se = if (n_valid > 0L) {
      sqrt(estimated * (1 - estimated) / n_valid)
    } else NA_real_
  )
}))
print(summary_table, row.names = FALSE, digits = 4)
cat("Original fits with warnings:", sum(results$original_warnings), "\n")
cat("Bootstrap warned refits:", sum(results$warned),
    "; failed refits:", sum(results$failed), "\n")
cat("Missing intervals are NOT counted as failures of coverage, and\n")
cat("coverage conditional on evaluability is NOT unconditional coverage.\n")
