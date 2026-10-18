\name{pb_gof_mc_error}
\alias{pb_gof_mc_error}
\title{Monte Carlo uncertainty of a bootstrap goodness-of-fit p-value}
\usage{
pb_gof_mc_error(test, level = 0.95)
}
\arguments{
\item{test}{A \code{pb_gof} object returned by \code{\link{pb_gof}}.}
\item{level}{Confidence level for the exact binomial limits.}
}
\description{
Quantifies simulation uncertainty in a parametric-bootstrap goodness-of-fit tail probability.
}
\details{
The original add-one corrected p-value is \eqn{(1+k)/(1+B)}, with \eqn{k}
selected-tail exceedances among \eqn{B} successful refits. The plug-in
Monte Carlo standard error and exact Clopper-Pearson interval apply to the
raw tail probability \eqn{k/B}, not the add-one adjusted p-value. When
no simulated value is as extreme as the observation, the plug-in standard
error is zero, while the exact confidence interval has a positive upper
endpoint. These calculations condition on the fitted model and successful,
independent refits and do not account for selective refit failure or
model misspecification.
}
\value{
A one-row data frame with \code{tail}, \code{p_value},
\code{tail_probability}, \code{mc_standard_error}, \code{lower}, \code{upper},
\code{exceedances}, \code{valid_replicates}, and \code{failed_replicates}.
}
\examples{
fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
check <- pb_gof(fit, n = 30, seed = 1)
pb_gof_mc_error(check)
}
\seealso{
\code{\link{pb_plot_gof}}, \code{\link{pb_lrt_mc_error}}
}
