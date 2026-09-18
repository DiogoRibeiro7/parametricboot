# Small fitted models shared across tests.

fit_binomial <- function() {
  stats::glm(vs ~ mpg, data = mtcars, family = stats::binomial())
}

fit_gaussian <- function() {
  stats::lm(mpg ~ wt + hp, data = mtcars)
}

# Small logistic fits occasionally hit separation in a replicate, which is
# reported as a warning; it is irrelevant to what the tests check.
boot_binomial <- function(n = 20, ...) {
  suppressWarnings(pb_simulate(fit_binomial(), n = n, seed = 1, ...))
}
