% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/get_fcl.R
\name{get_fcl}
\alias{get_fcl}
\title{Calculate Food chain length}
\usage{
get_fcl(N, lambda_b)
}
\arguments{
\item{N}{Matrix where rows (\code{n=3}) are abundances for species B, C and P, and columns (\code{n = n_patch}) describe each patch in the simulation}

\item{lambda_b}{Proportion of B in P's diet.}
}
\value{
\code{fcl} numeric vector of length = \code{n_patch} describing food chain length in each patch
}
\description{
Internal function used by \code{igp_sim()} to caluclate food chain length in a patch
}
