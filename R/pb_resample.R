#' Resample the rows of a data frame with replacement
#'
#' A small helper for the *nonparametric* (case-resampling) bootstrap, useful
#' as a point of comparison for the parametric bootstrap of [pb_simulate()].
#'
#' @param data Data frame to resample.
#' @param size Number of rows to draw. Defaults to `nrow(data)`.
#'
#' @return A data frame with `size` rows drawn with replacement from `data`.
#'
#' @examples
#' set.seed(1)
#' boot_cars <- pb_resample(mtcars)
#' coef(lm(mpg ~ wt, data = boot_cars))
#' @export
pb_resample <- function(data, size = nrow(data)) {
  if (!is.data.frame(data) || nrow(data) == 0L) {
    pb_abort("`data` must be a data frame with at least one row.")
  }
  size <- pb_check_count(size, "size")
  data[sample.int(nrow(data), size = size, replace = TRUE), , drop = FALSE]
}
