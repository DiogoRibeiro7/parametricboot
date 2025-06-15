\name{pb_plot_diagnostics}
\alias{pb_plot_diagnostics}
\title{Plot diagnostic information for bootstrap replicates}
\description{Create a trace plot of parameter estimates across replicates.}
\usage{pb_plot_diagnostics(results, parameter)}
\arguments{
  \item{results}{Output from \code{pb_simulate()}.}
  \item{parameter}{Parameter name to plot.}
}
\value{A \code{ggplot} object.}
\examples{
## pb_plot_diagnostics(res, "x")
}
