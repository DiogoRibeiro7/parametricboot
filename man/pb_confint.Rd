\name{pb_confint}
\alias{pb_confint}
\title{Bootstrap confidence intervals}
\description{Compute percentile confidence intervals from bootstrap results.}
\usage{pb_confint(results, level = 0.95)}
\arguments{
  \item{results}{Output from \code{pb_simulate()}.}
  \item{level}{Confidence level between 0 and 1.}
}
\value{A data frame with lower and upper bounds.}
\examples{
## pb_confint(res)
}
