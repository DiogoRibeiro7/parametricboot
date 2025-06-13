#' Plot predictive distributions from bootstrap models
#'
#' @param results Output from `pb_simulate()`.
#' @param newdata New data for prediction.
#' @param parameter Name of variable for x-axis if applicable.
#' @return A ggplot object.
#' @export
pb_plot_predictions <- function(results, newdata, parameter) {
  preds <- pb_predict_boot(results, newdata)
  df <- data.frame(pred = as.vector(preds))
  ggplot2::ggplot(df, ggplot2::aes(x = pred)) +
    ggplot2::geom_density(fill = "steelblue", alpha = 0.4) +
    ggplot2::labs(x = parameter, y = "Density", title = "Bootstrap Predictions") +
    ggplot2::theme_minimal()
}
