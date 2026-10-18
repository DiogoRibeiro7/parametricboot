\name{pb_gof}
\alias{pb_gof}
\title{Parametric-bootstrap goodness-of-fit test}
\usage{
pb_gof(
  model,
  n = 1000,
  statistic = c("deviance", "pearson", "zeros"),
  seed = NULL,
  workers = 1L,
  tail = c("greater", "less")
)
}
\arguments{
\item{model}{Supported binomial, Poisson or MASS negative-binomial GLM.}
\item{n}{Positive number of bootstrap replicates.}
\item{statistic}{Deviance, Pearson residual sum of squares, or zero count.}
\item{seed}{Optional reproducibility seed.}
\item{workers}{Number of processes for refitting.}
\item{tail}{Bootstrap reference-distribution tail, \"greater\" (default,
including large statistics or excess zeros) or \"less\" (including
small statistics or a zero-count deficit). Both include ties.}
}
\description{
Simulates and refits responses under a fitted count or binomial regression
model to approximate the goodness-of-fit statistic's reference distribution.
}
\details{
The selected-tail p-value uses (1 + tail exceedances) /
(1 + valid replicates), with equal values counted as exceedances.
Failed refits are excluded. This procedure is conditional on the fitted
sampling model and does not prove model correctness. The zero-count
statistic is supported only for unweighted count data.
}
\value{
A \code{pb_gof} object with fields \code{statistic}, \code{observed},
\code{reference}, \code{p_value}, \code{tail}, \code{n}, \code{failed},
\code{warned}, \code{model}, \code{seed}, and \code{call}.
}
\examples{
fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
pb_gof(fit, n = 30, seed = 1)
}
