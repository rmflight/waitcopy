% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/copy_files.R
\name{wait_copy}
\alias{wait_copy}
\title{wait copy}
\usage{
wait_copy(file_list, to_dir = ".", json_meta = "all_meta_data.json",
  tmp_loc = "/tmp", clean_file_fun = clean_filename, time_limit = TRUE,
  start_time = hours(20), stop_time = hours(30), time_zone = NULL,
  wait_check = 1800, n_check = Inf, wait_files = 10, pause_wait = 10,
  pause_file = 2)
}
\arguments{
\item{file_list}{a character vector of files to copy from}

\item{to_dir}{where to copy the files to}

\item{json_meta}{the json meta flat file}

\item{tmp_loc}{a temp file location}

\item{clean_file_fun}{function to use for cleaning up the file name?}

\item{time_limit}{only copy during a certain time?}

\item{start_time}{when to start copying}

\item{stop_time}{when to stop copying}

\item{time_zone}{what time zone are we in}

\item{wait_check}{how long to wait before checking again}

\item{n_check}{how many times to try before giving up}

\item{wait_files}{how many files before pausing}

\item{pause_wait}{how long to pause when the wait limit is reached}

\item{pause_file}{how long to pause between every file}
}
\value{
logical
}
\description{
Copy files from one location to another, during set hours if desired. This
is very useful for copying from networked drives that get a lot of activity
during the day.
}
\details{
\enumerate{
\item \strong{Limiting by time of day}: if \code{time_limit = TRUE}, the \code{start_time} and
\code{stop_time} are assumed to be on a
per day basis, so they should be encoded as the number of hours from midnight.
The function actually does a periodic check as to whether the
\code{start_time} is ahead of it, and if it is not, then it will create
a new time interval for the copying to be allowed. Default is from 8pm (20:00)
to 6am (30:00). The \code{wait_check} parameter sets how often to wait before checking
the time again (default is 1800 seconds / 30 minutes), and \code{n_check} parameter
defines how many times to check if the copying can be done (defaults to infinite).
\item \strong{Time Zone}: Provide your time zone so that the time functionality works
properly!
\item \strong{Waiting Between Copies}: In addition to only copying between certain hours,
it is possible to set how long to pause between each file using \code{pause_file},
default is 2 seconds, and also a longer interval after copying several files
using \code{wait_files} (10 files) and \code{pause_wait} (10 seconds).
\item \strong{Checking for files}: It is recommended before running \code{wait_copy} to
first run \code{check_files_exist} on the file list to copy to make sure that
you are passing valid file paths.
}
}
\examples{
\dontrun{

  # assume files are in /home/tmp/
  # assume current working directory is where to copy to
  file_list <- dir(".", full.names = TRUE)
  wait_copy(file_list) # copy between 8pm and 6am

  # no time limit for copying
  wait_copy(file_list, time_limit = FALSE)

  # copy from 10am to 1pm (13:00)
  wait_copy(file_list, start_time = hours(10), stop_time = hours(13))

  # stop checking if can copy after particular number of checks (3)
  wait_copy(file_list, n_check = 3)

  # check every 30 seconds instead of 30 minutes
  wait_copy(file_list, wait_check = 30)

  # pause 4 seconds between each file
  wait_copy(file_list, pause_file = 4)

  # pause 30 seconds after every 20 files
  wait_copy(file_list, wait_files = 20, pause_wait = 30)

  # don't rename the files
  wait_copy(file_list, clean_file_fun = NULL)

  # use make.names instead
  wait_copy(file_list, clean_file_fun = make.names)

}
}
