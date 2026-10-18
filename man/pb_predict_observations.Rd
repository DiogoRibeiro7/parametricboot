\name{pb_predict_observations}
\alias{pb_predict_observations}
\title{Simulate future observations from parametric bootstrap refits}
\usage{
pb_predict_observations(results, newdata, seed = NULL)
}
\arguments{
\item{results}{A \code{pb_boot} object from \code{\link{pb_simulate}}
or \code{\link{pb_parallel}}, fitted with \code{keep_fits = TRUE}.}
\item{newdata}{Nonempty data frame of covariates for future observations.}
\item{seed}{Optional seed for future response sampling, separate from
the original bootstrap seed.}
}
\description{
Draws observation-level outcomes from the sampling model of each successful
bootstrap refit, incorporating both fitted-model and process uncertainty.
}
\details{
Initially supported: unweighted Gaussian linear models, unweighted
Poisson GLMs, and unweighted negative-binomial models fitted using
\code{MASS::glm.nb()}. Gaussian observations are sampled using
\code{rnorm()} with each refit's residual standard deviation;
Poisson observations use \code{rpois()} and negative-binomial
observations use \code{rnbinom()} with each refit's re-estimated
\code{theta}. Binomial, mixed-effects, and Cox models, as well as
non-unit case weights, are not supported by this function.
The approach is model-conditional predictive simulation rather
than an exact small-sample frequentist prediction interval.
}
\value{
A numeric matrix with one row per future observation and one
column per successful bootstrap refit. Each entry is a newly
sampled observation conditional on the corresponding refitted model.
}
\examples{
fit <- lm(mpg ~ wt + hp, data = mtcars)
boot <- pb_simulate(fit, n = 30, seed = 1, keep_fits = TRUE)
new_cars <- mtcars[1:2, c("wt", "hp")]
draws <- pb_predict_observations(boot, new_cars, seed = 2)
dim(draws)
}
\seealso{
\code{\link{pb_predict_interval}}, \code{\link{pb_predict_boot}}
}
