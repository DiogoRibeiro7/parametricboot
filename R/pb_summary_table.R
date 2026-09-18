#' Summarise bootstrap statistics and confidence intervals
#'
#' Combines [pb_key_stats()] and [pb_confint()] into a single table.
#'
#' @inheritParams pb_confint
#'
#' @return A data frame with one row per coefficient: the columns of
#'   [pb_key_stats()] followed by the `lower` and `upper` confidence limits of
#'   [pb_confint()].
#'
#' @examples
#' fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
#' res <- pb_simulate(fit, n = 50, seed = 1)
#' pb_summary_table(res)
#' @export
pb_summary_table <- function(results, level = 0.95,
                             type = c("percentile", "basic", "normal", "student")) {
  key_stats <- pb_key_stats(results, level = level)
  ci <- pb_confint(results, level = level, type = type)
  cbind(key_stats, ci[c("lower", "upper")])
}
