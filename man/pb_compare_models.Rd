\name{pb_compare_models}
\alias{pb_compare_models}
\title{Compare multiple models using parametric bootstrap}
\description{Run bootstrap simulations for each model and summarize a metric.}
\usage{pb_compare_models(models, n = 100, metric = stats::AIC)}
\arguments{
  \item{models}{A list of fitted models.}
  \item{n}{Number of bootstrap replicates for each model.}
  \item{metric}{Function to summarize each fitted model.}
}
\value{A data frame with a metric value for each model.}
\examples{
## pb_compare_models(list(fit1, fit2))
}
