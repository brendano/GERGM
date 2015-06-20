% Generated by roxygen2 (4.1.0.9001): do not edit by hand
% Please edit documentation in R/gergm.R
\name{gergm}
\alias{gergm}
\title{A Function to estimate a GERGM.}
\usage{
gergm(formula, network_is_directed = c(TRUE, FALSE),
  use_MPLE_only = c(FALSE, TRUE), data_transformation = NULL,
  estimation_method = c("Gibbs", "Metropolis"),
  maximum_number_of_lambda_updates = 10,
  maximum_number_of_theta_updates = 100,
  number_of_networks_to_simulate = 500, thin = 1, proposal_variance = 0.1,
  exponential_weights = NULL, downweight_statistics_together = TRUE,
  MCMC_burnin = 100, seed = 123, convergence_tolerance = 0.01,
  MPLE_gain_factor = 0)
}
\arguments{
\item{formula}{A formula object that specifies the relationship between statistics and the observed network. Currently, the following statistics can be specified: c("out2star", "in2star",     "ctriads", "recip", "ttriads", "edgeweight").}

\item{network_is_directed}{Logical specifying whether or not the observed network is directed. Default is TRUE.}

\item{use_MPLE_only}{Logical specifying whether or not only the maximum pseudo likelihood estimates should be obtained. In this case, no simulations will be performed. Default is FALSE.}

\item{data_transformation}{An n x n x m array where each of m layers contains a covariate that models the transform of the unbounded weighted network to a network whose edges are all on the unit interval. Default is NULL.}

\item{estimation_method}{Simulation method for MCMC estimation. Default is "Gibbs" which will generally be faster with well behaved networks but will not allow for exponential downweighting.}

\item{maximum_number_of_lambda_updates}{Maximum number of iterations of outer MCMC loop which alternately estimates transform parameters and ERGM parameters. In the case that data_transformation = NULL, this argument does not matter. Default is 10.}

\item{maximum_number_of_theta_updates}{Maximum number of iterations within the MCMC inner loop which estimates the ERGM parameters. Default is 100.}

\item{number_of_networks_to_simulate}{Number of simulations generated for estimation via MCMC. Default is 500.}

\item{thin}{The proportion of samples that are kept from each simulation. For example, thin = 1/200 will keep every 200th network in the overall simulated sample. Default is 1.}

\item{proposal_variance}{The variance specified for the Metropolis Hastings simulation method. This parameter is inversely proportional to the average acceptance rate of the M-H sampler and should be adjusted so that the average acceptance rate is approximately 0.25.         Default is 0.1.}

\item{exponential_weights}{A vector of weights specifying the down weighting (via exponentiation) of each possible statistic. This vector must be the same length as the number of statistics used in object. Values are between 0 and 1. Default is NULL specifying a 1 for each statistic.}

\item{downweight_statistics_together}{Logical specifying whether or not the weights should be applied inside or outside the sum. Default is TRUE and user should not select FALSE under normal circumstances.}

\item{MCMC_burnin}{Number of samples from the MCMC simulation procedure that will be discarded before drawing the samples used for estimation. Default is 100.}

\item{seed}{Seed used for reproducibility. Default is 123.}

\item{convergence_tolerance}{Threshold designated for stopping criterion. If the difference of parameter estimates from one iteration to the next all have a p-value (under a paired t-test) greater than this value, the parameter estimates are declared to have converged. Default is 0.01.}

\item{MPLE_gain_factor}{Multiplicative constant between 0 and 1 that controls how far away the initial theta estimates will be from the standard MPLEs via a one step Fisher update. In the case of strongly dependent data, it is suggested to use a value of 0.10. Default is 0.}
}
\value{
A gergm object containing parameter estimates.
}
\description{
A Function to estimate a GERGM.
}
