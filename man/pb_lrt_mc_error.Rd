\name{pb_lrt_mc_error}
\alias{pb_lrt_mc_error}
\title{Monte Carlo uncertainty for a parametric bootstrap likelihood-ratio p-value}
\usage{
pb_lrt_mc_error(test, level = 0.95)
}
\arguments{
\item{test}{A \code{pb_lrt} object returned by \code{\link{pb_lrt}}.}
\item{level}{Confidence level for the exact binomial interval.}
}
\description{
Reports Monte Carlo uncertainty for the likelihood-ratio bootstrap exceedance probability, conditional on successful refits.
}
\details{
The original bootstrap p-value \eqn{(1+k)/(1+B)} is preserved, where \eqn{k} of the \eqn{B} valid bootstrap statistics exceed or equal the observed test statistic.
The Monte Carlo standard error is the binomial plug-in estimate based on \eqn{k/B}; the interval is the exact Clopper-Pearson interval for that exceedance probability. When \eqn{k=0}, the plug-in standard error is zero but the interval has a positive upper limit. Failed refits are excluded. The interval does not cover model or parameter uncertainty and is conditional on the validity and independence of successful bootstrap replicates.
}
\value{
A one-row data frame with \code{p_value}, \code{exceedance_probability}, \code{mc_standard_error}, \code{lower}, \code{upper}, \code{exceedances}, \code{valid_replicates}, and \code{failed_replicates}.
}
\examples{
null <- lm(mpg ~ wt, data = mtcars)
alt <- lm(mpg ~ wt + hp, data = mtcars)
test <- pb_lrt(null, alt, n = 30, seed = 1)
pb_lrt_mc_error(test)
}
