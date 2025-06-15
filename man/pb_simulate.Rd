\name{pb_simulate}
\alias{pb_simulate}
\title{Run parametric bootstrap replicates}
\description{Run parametric bootstrap replicates for a fitted model.}
\usage{pb_simulate(model, n = 100, ...)}
\arguments{
  \item{model}{A fitted \code{glm}, \code{glmer}, or \code{coxph} model.}
  \item{n}{Number of bootstrap replicates.}
  \item{...}{Additional arguments passed to model fitting.}
}
\value{A list of fitted models of class \code{pb_boot}.}
\examples{
## res <- pb_simulate(fit, 100)
}
