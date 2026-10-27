# Opt-in calibration experiment for the lower tail of zero-count GOF.
# Run after installing parametricboot:
# OUTER_N=200 BOOT_N=399 Rscript inst/validation/poisson-zero-deficit.R
# All data-generating settings are fixed before simulation.

if (!requireNamespace("parametricboot", quietly = TRUE) ||
    !requireNamespace("withr", quietly = TRUE)) {
  stop("Install parametricboot and withr before running the experiment.")
}

read_count <- function(name, default) {
  raw <- Sys.getenv(name, unset = as.character(default))
  value <- suppressWarnings(as.integer(raw))
  if (length(value) != 1L || is.na(value) || value < 2L ||
      !identical(as.character(value), raw)) {
    stop(sprintf("%s must be an integer >= 2.", name))
  }
  value
}

outer_n <- read_count("OUTER_N", 40L)
boot_n <- read_count("BOOT_N", 99L)
alpha <- 0.05
x <- rep(seq(-1, 1, length.out = 15L), each = 8L)
mu <- exp(0.3 + 0.4 * x)

# Positive-count conditioning removes zeros while leaving the covariates
# unchanged. This is intentionally a misspecified alternative to Poisson.
positive_poisson <- function(lambda) {
  values <- stats::rpois(length(lambda), lambda)
  missing <- which(values == 0L)
  while (length(missing)) {
    values[missing] <- stats::rpois(length(missing), lambda[missing])
    missing <- which(values == 0L)
  }
  values
}

experiment <- withr::with_seed(7032L, {
  rows <- vector("list", 2L * outer_n)
  index <- 0L
  for (scenario in c("poisson_null", "zero_truncated")) {
    for (i in seq_len(outer_n)) {
      y <- if (scenario == "poisson_null") {
        stats::rpois(length(mu), mu)
      } else {
        positive_poisson(mu)
      }
      dat <- data.frame(x = x, y = y)
      fit <- stats::glm(y ~ x, data = dat, family = stats::poisson())
      # A deficit of zero observations belongs to the lower tail.
      test <- tryCatch(suppressWarnings(parametricboot::pb_gof(
        fit, n = boot_n, statistic = "zeros", tail = "less", seed = i
      )), error = function(e) NULL)
      index <- index + 1L
      rows[[index]] <- data.frame(
        scenario = scenario, replicate = i,
        p_value = if (is.null(test)) NA_real_ else test$p_value,
        valid_refits = if (is.null(test)) NA_integer_ else sum(!test$failed),
        failed_refits = if (is.null(test)) NA_integer_ else sum(test$failed)
      )
    }
  }
  do.call(rbind, rows)
})

out <- do.call(rbind, lapply(split(experiment, experiment$scenario),
  function(part) {
    valid <- is.finite(part$p_value)
    B <- sum(valid)
    rejected <- sum(part$p_value[valid] <= alpha)
    rate <- if (B > 0L) rejected / B else NA_real_
    data.frame(
      scenario = part$scenario[1L], outer_total = nrow(part),
      evaluable = B, rejected = rejected, rejection_rate = rate,
      outer_mc_se = if (B > 0L) sqrt(rate * (1 - rate) / B) else NA_real_,
      mean_valid_refits = if (B > 0L) mean(part$valid_refits[valid]) else NA_real_
    )
  }))
print(out, row.names = FALSE, digits = 4)
cat("Nominal alpha:", alpha, "\n")
cat("Null rejection estimates type-I error; zero-truncated rejection",
    " estimates power against this specific alternative.\n")
cat("Rates are conditional on evaluability, with discrete finite-bootstrap p-values.\n")
