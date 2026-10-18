\name{pb_predict_interval}
\alias{pb_predict_interval}
\title{Prediction intervals for new observations}
\usage{
pb_predict_interval(results, newdata, level = 0.95, seed = NULL)
}
\arguments{
\item{results}{A \code{pb_boot} object from \code{\link{pb_simulate}}
or \code{\link{pb_parallel}}, with retained refits.}
\item{newdata}{Nonempty data frame giving future covariates.}
\item{level}{Predictive quantile interval level, strictly between zero and one.}
\item{seed}{Optional RNG seed for future outcomes, independent from the
bootstrap fit seed.}
}
\description{
Constructs a model-conditional prediction interval for a future response,
rather than a confidence interval for the fitted conditional mean.
}
\details{
For each bootstrap refit, an additional observation is independently
drawn from the fitted sampling model. Empirical quantiles of these
draws combine parameter uncertainty and response noise. The original
model's conditional mean is reported separately as \code{prediction}.
The intervals are approximate, conditional on the model assumptions,
and require retained refits. The method initially supports unweighted
Gaussian linear, Poisson GLM and MASS negative-binomial models only.
}
\value{
Data frame with columns \code{prediction}, \code{lower}, \code{upper},
and \code{successful_replicates}, one row for each future observation.
}
\examples{
fit <- lm(mpg ~ wt + hp, data = mtcars)
boot <- pb_simulate(fit, n = 30, seed = 1)
pb_predict_interval(boot, mtcars[1:2, c("wt", "hp")],
                    level = 0.9, seed = 2)
}
\seealso{
\code{\link{pb_predict_observations}}, \code{\link{pb_predict_boot}}
}
