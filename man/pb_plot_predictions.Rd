\name{pb_plot_predictions}
\alias{pb_plot_predictions}
\title{Plot predictive distributions from bootstrap models}
\description{Visualize predictive distributions using bootstrap replicates.}
\usage{pb_plot_predictions(results, newdata, parameter)}
\arguments{
  \item{results}{Output from \code{pb_simulate()}.}
  \item{newdata}{New data frame for prediction.}
  \item{parameter}{Optional variable name for the x-axis.}
}
\value{A \code{ggplot} object.}
\examples{
## pb_plot_predictions(res, newdata, "x")
}
