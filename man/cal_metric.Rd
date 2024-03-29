% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/cal_metric.R
\name{cal_metric}
\alias{cal_metric}
\title{Obtain calibration metrics}
\usage{
cal_metric(predictr = NULL, fit = NULL, hltest = F, risk_ntile = 10)
}
\arguments{
\item{predictr}{Output from the predictr function (alternative to fit parameter)}

\item{fit}{Logistic regression fit object (alternative to predictr parameter)}

\item{hltest}{Logical value specifying if a Hosmer–Lemeshow test should be performed (default=FALSE)}

\item{risk_ntile}{Numerical value specifying the number of quantiles for the Hosmer–Lemeshow test (default=10)}
}
\value{
Dataframe with the calibration slope and intecept (+/- Hosmer–Lemeshow test)
}
\description{
Use to obtain calibration metrics for a predictive model
}
