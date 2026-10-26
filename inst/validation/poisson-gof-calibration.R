# Opt-in calibration experiment for count-model bootstrap goodness of fit.
# Run from a locally installed development package:
# OUTER_N=100 BOOT_N=399 Rscript inst/validation/poisson-gof-calibration.R
#
# This reports simulation outcomes; no rejection-rate claim is hard-coded.

if (!requireNamespace("parametricboot", quietly = TRUE) ||
    !requireNamespace("withr", quietly = TRUE)) {
  stop("Install parametricboot and withr before running this experiment.")
}

read_count <- function(key, default) {
  text <- Sys.getenv(key, unset = as.character(default))
  value <- suppressWarnings(as.integer(text))
  if (length(value) != 1L || is.na(value) || value < 2L ||
      !identical(as.character(value), text)) {
    stop(sprintf("%s must be an integer >= 2.", key))
  }
  value
}

outer_n <- read_count("OUTER_N", 40L)
boot_n <- read_count("BOOT_N", 99L)
alpha <- 0.05
zero_inflation <- 0.25
x <- rep(seq(-1, 1, length.out = 15L), each = 8L)
mu <- exp(0.3 + 0.4 * x)

# Both scenarios use the same covariate design. Under the alternative,
# a structural-zero component introduces misspecification.
experiment <- withr::with_seed(7031L, {
  rows <- vector("list", 2L * outer_n)
  k <- 0L
  for (scenario in c("poisson_null", "zero_inflated")) {
    for (i in seq_len(outer_n)) {
      y <- stats::rpois(length(mu), lambda = mu)
      if (scenario == "zero_inflated") {
        y[stats::runif(length(y)) < zero_inflation] <- 0L
      }
      dat <- data.frame(x = x, y = y)
      fit <- stats::glm(y ~ x, family = stats::poisson(), data = dat)
      # Investigate excess zeros with the upper tail of the zero statistic.
      gof <- tryCatch(suppressWarnings(parametricboot::pb_gof(
        fit, n = boot_n, statistic = "zeros", seed = i, tail = "greater"
      )), error = function(e) NULL)
      k <- k + 1L
      rows[[k]] <- data.frame(
        scenario = scenario,
        replicate = i,
        p_value = if (is.null(gof)) NA_real_ else gof$p_value,
        valid_refits = if (is.null(gof)) NA_integer_ else
          sum(!gof$failed),
        failed_refits = if (is.null(gof)) NA_integer_ else
          sum(gof$failed)
      )
    }
  }
  do.call(rbind, rows)
})

report <- do.call(rbind, lapply(split(experiment, experiment$scenario), function(part) {
  valid <- is.finite(part$p_value)
  n_valid <- sum(valid)
  rejections <- sum(part$p_value[valid] <= alpha)
  rate <- if (n_valid > 0L) rejections / n_valid else NA_real_
  data.frame(
    scenario = part$scenario[1L],
    outer_total = nrow(part),
    evaluable = n_valid,
    rejected = rejections,
    rejection_rate = rate,
    outer_mc_se = if (n_valid > 0L) {
      sqrt(rate * (1 - rate) / n_valid)
    } else NA_real_,
    mean_valid_refits = if (n_valid > 0L) {
      mean(part$valid_refits[valid])
    } else NA_real_
  )
}))
print(report, row.names = FALSE, digits = 4)
cat("Nominal alpha:", alpha, "; structural zero probability:",
    zero_inflation, "\n")
cat("Rates are conditional on evaluability; finite inner-bootstrap",
    " p-values are discrete.\n")
