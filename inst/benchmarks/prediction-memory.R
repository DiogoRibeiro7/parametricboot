# Reproducible retained-refit versus cached-prediction memory benchmark.
# Run from an installed development package:
# Rscript inst/benchmarks/prediction-memory.R
#
# These sizes describe retained R objects, not peak process memory.
# Times are elapsed wall-clock measurements, not controlled performance tests.

if (!requireNamespace("parametricboot", quietly = TRUE)) {
  stop("Install parametricboot before running this benchmark.")
}

# Use a moderately large reproducible design and a small prediction target.
n_rows <- 2000L
n_replicates <- 60L
training <- withr::with_seed(2026L, {
  x <- stats::rnorm(n_rows)
  data.frame(x = x, y = 2 + 0.7 * x + stats::rnorm(n_rows))
})
newdata <- data.frame(x = seq(-1, 1, length.out = 12L))
fit <- stats::lm(y ~ x, data = training)

# Identical bootstrap seeds allow a direct equivalence check.
full_timing <- system.time({
  full <- parametricboot::pb_simulate(
    fit, n = n_replicates, seed = 31L,
    newdata = newdata, keep_fits = TRUE
  )
})
cached_timing <- system.time({
  cached <- parametricboot::pb_simulate(
    fit, n = n_replicates, seed = 31L,
    newdata = newdata, keep_fits = FALSE
  )
})

full_predictions <- parametricboot::pb_predict_boot(full)
cached_predictions <- parametricboot::pb_predict_boot(cached)
if (!isTRUE(all.equal(full_predictions, cached_predictions,
                      tolerance = 1e-12))) {
  stop("Cached and retained-refit predictions differ.")
}
if (!identical(full$failed, cached$failed)) {
  stop("Refit failure flags differ between benchmark modes.")
}

# Report retained object size only; input training data may be shared.
full_bytes <- as.numeric(utils::object.size(full))
cached_bytes <- as.numeric(utils::object.size(cached))
out <- data.frame(
  mode = c("retained_refits", "cached_predictions"),
  replicates = rep(n_replicates, 2L),
  model_rows = rep(n_rows, 2L),
  prediction_rows = rep(nrow(newdata), 2L),
  result_MiB = c(full_bytes, cached_bytes) / 1024^2,
  elapsed_seconds = c(
    unname(full_timing["elapsed"]),
    unname(cached_timing["elapsed"])
  ),
  stringsAsFactors = FALSE
)
print(out, row.names = FALSE, digits = 4)
cat(sprintf(
  "Retained-object size ratio (full/cached): %.2fx\\n",
  full_bytes / cached_bytes
))
cat("Measurements depend on R version, machine, and implementation.\\n")
