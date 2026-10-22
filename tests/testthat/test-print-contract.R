# Exact output contracts for the public print method. These tests complement
# the broader smoke tests without depending on the testthat snapshot format.

test_that("Gaussian print output remains stable with discarded refits", {
  boot <- pb_simulate(fit_gaussian(), n = 4, seed = 112,
                      keep_fits = FALSE)
  expect_false(any(boot$failed))
  expect_false(any(boot$warned))
  output <- utils::capture.output(value <- withVisible(print(boot)))
  expect_identical(output, c(
    "<pb_boot> Parametric bootstrap",
    "  Model:      lm (gaussian)",
    "  Replicates: 4",
    "  Terms:      (Intercept), wt, hp",
    "  Refitted models were not kept (`keep_fits = FALSE`)."
  ))
  expect_false(value$visible)
  expect_identical(value$value, boot)
})

test_that("Warnings and dropped-refit counts have stable presentation", {
  boot <- pb_simulate(fit_gaussian(), n = 4, seed = 112)
  # Flags are assigned to a valid bootstrap object to isolate formatting
  # from the stochastic frequency of convergence warnings.
  boot$warned[1:2] <- TRUE
  boot$failed[1] <- TRUE
  output <- utils::capture.output(print(boot))
  expect_identical(output, c(
    "<pb_boot> Parametric bootstrap",
    "  Model:      lm (gaussian)",
    "  Replicates: 4 (1 dropped, 1 with warnings)",
    "  Terms:      (Intercept), wt, hp"
  ))
})

test_that("All-warning and all-failure flags do not break print output", {
  boot <- pb_simulate(fit_gaussian(), n = 3, seed = 11,
                      keep_fits = FALSE)
  boot$warned[] <- TRUE
  expect_match(paste(utils::capture.output(print(boot)), collapse = "\n"),
               "3 with warnings", fixed = TRUE)
  boot$failed[] <- TRUE
  expect_match(paste(utils::capture.output(print(boot)), collapse = "\n"),
               "3 dropped", fixed = TRUE)
  expect_false(any(grepl("with warnings",
    utils::capture.output(print(boot)), fixed = TRUE)))
})
