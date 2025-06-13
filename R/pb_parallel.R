#' Run bootstrap replicates in parallel
#'
#' @param model A fitted model object.
#' @param n Number of replicates.
#' @param workers Number of parallel workers.
#' @return A list of fitted models.
#' @export
pb_parallel <- function(model, n = 100, workers = parallel::detectCores()) {
  cl <- parallel::makeCluster(workers)
  on.exit(parallel::stopCluster(cl))
  parallel::clusterExport(cl, varlist = c("model"), envir = environment())
  sims <- parallel::parLapply(cl, seq_len(n), function(i) {
    y <- stats::simulate(model, nsim = 1)[[1]]
    data <- model.frame(model)
    data[[all.vars(formula(model))[1]]] <- y
    stats::update(model, data = data)
  })
  structure(list(original = model, replicates = sims), class = "pb_boot")
}
