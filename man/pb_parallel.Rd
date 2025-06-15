\name{pb_parallel}
\alias{pb_parallel}
\title{Run bootstrap replicates in parallel}
\description{Use multiple cores to simulate bootstrap replicates.}
\usage{pb_parallel(model, n = 100, workers = parallel::detectCores())}
\arguments{
  \item{model}{A fitted model object.}
  \item{n}{Number of replicates.}
  \item{workers}{Number of parallel workers.}
}
\value{A list of fitted models of class \code{pb_boot}.}
\examples{
## pb_parallel(fit, n = 100)
}
