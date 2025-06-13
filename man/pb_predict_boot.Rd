\name{pb_predict_boot}
\alias{pb_predict_boot}
\title{Predict with bootstrap uncertainty}
\description{Generate predictions from each bootstrap replicate.}
\usage{pb_predict_boot(results, newdata = NULL)}
\arguments{
  \item{results}{Output from \code{pb_simulate()}.}
  \item{newdata}{New data frame for prediction.}
}
\value{A matrix of predictions.}
\examples{
## pb_predict_boot(res, newdata)
}
