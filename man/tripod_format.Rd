% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tripod_format.R
\name{tripod_format}
\alias{tripod_format}
\title{Format TRIPOD data prior to plotting}
\usage{
tripod_format(data, id = "id", type = "type")
}
\arguments{
\item{data}{TRIPOD data in format as specified in  "example_tripod.csv".}

\item{id}{String specifying the column name containing the identifier for the specific paper/model.}

\item{type}{String specifying the column name containing the type of model ("d"=derivation, "dv" = "derivation and validation", "v" = validation)}
}
\value{
Tibble of TRIPOD data formatted for a TRIPOD plot.
}
\description{
Format TRIPOD data prior to plotting
}
