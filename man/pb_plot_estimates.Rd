\name{pb_plot_estimates}
\alias{pb_plot_estimates}
\title{Plot empirical vs bootstrap distributions}
\description{Create a density plot comparing empirical and bootstrap estimates.}
\usage{pb_plot_estimates(results, parameter)}
\arguments{
  \item{results}{Output from \code{pb_simulate()}.}
  \item{parameter}{Parameter name to plot.}
}
\value{A \code{ggplot} object.}
\examples{
## pb_plot_estimates(res, "x")
}
