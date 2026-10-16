\name{pb_confint_mc_error}
\alias{pb_confint_mc_error}
\title{Monte Carlo precision of bootstrap confidence interval limits}
\usage{
pb_confint_mc_error(
  results,
  level = 0.95,
  type = c("percentile", "basic", "student"),
  mc_level = 0.95
)
}
\arguments{
\item{results}{A \code{pb_boot} object from \code{\link{pb_simulate}} or \code{\link{pb_parallel}}.}
\item{level}{Coverage level for the underlying bootstrap confidence interval.}
\item{type}{One of \code{"percentile"}, \code{"basic"}, or \code{"student"}. Rank bounds are not provided for normal-approximation intervals.}
\item{mc_level}{Per-endpoint Monte Carlo confidence level, separate from \code{level}.}
}
\description{
Reports finite-replicate uncertainty of the endpoints of quantile-based bootstrap confidence intervals.
}
\details{
Distribution-free order-statistic bounds for each bootstrap tail quantile are derived using binomial ranks, then mapped into percentile, basic or studentised confidence interval units. The Monte Carlo bounds apply separately to the lower and upper endpoint; they are not a joint region. Unbounded bounds signal too few bootstrap replicates to provide a finite rank guarantee for a tail quantile. The method conditions on independently simulated, successful finite refits and does not measure statistical sampling or model uncertainty. Parameters without usable studentised confidence intervals have missing Monte Carlo bounds.
}
\value{
A data frame with \code{term}, the original unmodified \code{lower} and \code{upper} confidence interval endpoints, \code{lower_mc_low}, \code{lower_mc_high}, \code{upper_mc_low}, \code{upper_mc_high}, and \code{replicates}.
}
\examples{
model <- lm(mpg ~ wt, data = mtcars)
result <- pb_simulate(model, n = 30, seed = 7, keep_fits = FALSE)
pb_confint_mc_error(result, level = 0.8, mc_level = 0.9)
}
\seealso{
\code{\link{pb_confint}}, \code{\link{pb_mc_error}}, \code{\link{pb_lrt_mc_error}}
}
