% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/copy_files.R
\name{check_files_exist}
\alias{check_files_exist}
\title{check files}
\usage{
check_files_exist(file_list, n_check = 10)
}
\arguments{
\item{file_list}{the list of files}

\item{n_check}{how many to check that they exist?}
}
\description{
check that requested files to copy actually exist, and warn the user
if any of them fail.
}
