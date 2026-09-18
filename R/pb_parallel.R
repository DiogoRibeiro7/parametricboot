#' Run parametric bootstrap replicates in parallel
#'
#' A drop-in replacement for [pb_simulate()] that distributes the model refits
#' over a local cluster of R processes.
#'
#' @details
#' The bootstrap responses are simulated in the calling process and only the
#' refits are distributed, so for a given `seed` the result is identical to
#' that of [pb_simulate()], whatever the number of workers.
#'
#' The workers are fresh R sessions: 'parametricboot' must be installed (not
#' just loaded with `devtools::load_all()`), and everything the model call
#' needs, such as weights or offsets, should be a column of `data` rather than
#' a variable in the global environment.
#'
#' Parallel execution has a start-up cost, so it only pays off when a single
#' refit is slow, as is typical for mixed models.
#'
#' @inheritParams pb_simulate
#' @param workers Number of parallel worker processes.
#'
#' @return An object of class `pb_boot`; see [pb_simulate()].
#'
#' @examples
#' \donttest{
#' fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
#' res <- pb_parallel(fit, n = 50, workers = 2, seed = 1)
#' res
#' }
#' @export
pb_parallel <- function(model, n = 100, workers = 2, ..., seed = NULL, keep_fits = TRUE) {
  pb_run(
    model,
    n = n, dots = list(...), seed = seed, keep_fits = keep_fits,
    workers = workers, call = match.call()
  )
}
