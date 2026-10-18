\name{pb_plot_gof}
\alias{pb_plot_gof}
\title{Plot a simulated goodness-of-fit reference distribution}
\usage{
pb_plot_gof(test, bins = 30L)
}
\arguments{
\item{test}{A \code{pb_gof} object returned by \code{\link{pb_gof}}.}
\item{bins}{Positive number of histogram bins.}
}
\description{
Plots valid bootstrap goodness-of-fit statistics against the observed statistic.
}
\details{
The histogram shows the empirical reference distribution without imposing
a chi-squared approximation. The dashed vertical line indicates the observed
discrepancy. The plot preserves discreteness and ties in the bootstrap values.
}
\value{
A \code{ggplot} object.
}
\examples{
fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
check <- pb_gof(fit, n = 30, seed = 1)
pb_plot_gof(check)
}
\seealso{
\code{\link{pb_gof}}, \code{\link{pb_gof_mc_error}}
}
