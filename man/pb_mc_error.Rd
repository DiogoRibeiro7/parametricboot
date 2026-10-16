\name{pb_mc_error}
\alias{pb_mc_error}
\title{Monte Carlo errors of bootstrap bias and standard error}
\usage{
pb_mc_error(results)
}
\arguments{
\item{results}{A \code{pb_boot} object from \code{\link{pb_simulate}} or \code{\link{pb_parallel}}.}
}
\description{
Reports the uncertainty from using a finite number of bootstrap refits to estimate bootstrap bias and standard deviation.
}
\details{
For each coefficient with B finite estimates, the Monte Carlo standard error of bias (conditional on the fitted model) is the bootstrap standard deviation divided by the square root of B. The Monte Carlo error of that standard deviation is estimated by a first-order delta method using the empirical fourth central moment. The latter is not estimated for fewer than four finite values or zero empirical dispersion. These quantities describe Monte Carlo precision, not uncertainty about the fitted model or estimator. Failed refits and non-finite coefficient estimates are excluded separately by parameter, and missingness may be selective.
}
\value{
A data frame with \code{term}, \code{replicates}, \code{failed_replicates}, \code{bias}, \code{bias_mc_se}, \code{std_error}, and \code{std_error_mc_se}. Here \code{std_error} means bootstrap standard deviation; \code{std_error_mc_se} is its Monte Carlo standard error.
}
\examples{
model <- lm(mpg ~ wt, data = mtcars)
result <- pb_simulate(model, n = 30, seed = 7, keep_fits = FALSE)
pb_mc_error(result)
}
\seealso{
\code{\link{pb_key_stats}}, \code{\link{pb_confint_mc_error}}, \code{\link{pb_lrt_mc_error}}
}
