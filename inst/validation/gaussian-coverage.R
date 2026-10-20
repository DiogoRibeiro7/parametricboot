# Repeated-sampling coverage experiment for Gaussian regression.
# Run after installing the development package:
# Rscript inst/validation/gaussian-coverage.R
#
# Environment variables OUTER_N and BOOT_N can increase precision.
# This is a deliberately transparent Monte Carlo experiment, not a
# finite-sample coverage guarantee for arbitrary data.

if (!requireNamespace("parametricboot", quietly = TRUE)) {
  stop("Install parametricboot before running this experiment.")
}
if (!requireNamespace("withr", quietly = TRUE)) {
  stop("Install the withr package before running this experiment.")
}

read_count <- function(name, default) {
  value <- Sys.getenv(name, unset = as.character(default))
  parsed <- suppressWarnings(as.integer(value))
  if (length(parsed) != 1L || is.na(parsed) || parsed < 2L ||
      !identical(as.character(parsed), value)) {
    stop(sprintf("%s must be an integer >= 2.", name))
  }
  parsed
}

outer_n <- read_count("OUTER_N", 80L)
boot_n <- read_count("BOOT_N", 199L)
sample_n <- 35L
beta <- c("(Intercept)" = 1.5, "x" = -0.7)
sigma <- 1.2
level <- 0.95

# Hold X fixed. The only sampling variation comes from Gaussian errors.
x <- seq(-1, 1, length.out = sample_n)
design <- cbind("(Intercept)" = 1, x = x)
stopifnot(qr(design)$rank == ncol(design))

experiment <- withr::with_seed(90210L, {
  result <- matrix(NA, nrow = outer_n, ncol = 3L,
                   dimnames = list(NULL, c("t_exact", "percentile", "student")))
  for (i in seq_len(outer_n)) {
    y <- as.numeric(design %*% beta) + stats::rnorm(sample_n, sd = sigma)
    fit <- stats::lm(y ~ x, data = data.frame(x = x, y = y))
    # Exact under the stated Gaussian, independent-error, fixed-X assumptions.
    exact <- stats::confint(fit, level = level)["x", ]
    result[i, "t_exact"] <- exact[1] <= beta["x"] && beta["x"] <= exact[2]

    # A fresh bootstrap is performed for each newly generated dataset.
    bootstrap <- parametricboot::pb_simulate(
      fit, n = boot_n, seed = i, keep_fits = FALSE
    )
    for (method in c("percentile", "student")) {
      limits <- parametricboot::pb_confint(
        bootstrap, level = level, type = method
      )
      row <- limits[limits$term == "x", , drop = FALSE]
      if (nrow(row) != 1L || !is.finite(row$lower) ||
          !is.finite(row$upper)) {
        stop(sprintf("Invalid %s interval in outer replicate %d.", method, i))
      }
      result[i, method] <- row$lower <= beta["x"] &&
        beta["x"] <= row$upper
    }
  }
  result
})

# Independent Bernoulli coverage indicators across outer experiments.
covered <- colSums(experiment)
estimates <- covered / outer_n
mc_se <- sqrt(estimates * (1 - estimates) / outer_n)
out <- data.frame(
  method = names(covered),
  covered = as.integer(covered),
  outer_replicates = outer_n,
  coverage = as.numeric(estimates),
  mc_se = as.numeric(mc_se),
  nominal = level,
  row.names = NULL
)
print(out, row.names = FALSE, digits = 4)
cat("Outer Monte Carlo error is distinct from inner bootstrap quantile error.\n")
cat("For the exact t interval, theoretical coverage is nominal under the model.\n")
