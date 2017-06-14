#' waitcopy.
#'
#' Copy files during particular times of day and with metadata.
#'
#' @section Functionality:
#'
#' `waitcopy` provides the function `wait_copy` that:
#' - will only copy files during a set time interval
#' - will wait a specific amount of time between file copies
#' - creates a json file with some limited meta-data about the file
#' - removes special characters from the file name
#'
#' @section Motivation:
#'
#' Imagine someone you work with has a hard drive that you need data from, but that
#' hard drive is only accessible via the network, mounted via SAMBA, and there are
#' potentially duplicate files with the same name, files with the same base name
#' that are different, and the file path provides some meta-information about the
#' sample. In addition, the file names have odd characters in them (spaces, colons, etc)
#' that make them a pain to work with from the command line on Linux, so you'd prefer
#' if they weren't there.
#'
#' The files are small, so even copying over the network is fast, but if you copy
#' too many too quickly during the day, you'll get complaints about hitting this shared
#' resource too often by the people who are local to it.
#'
#' @section Solution:
#'
#' So ideally, you want to copy the files only during certain hours, wait a little
#' bit between each copy operation, check for duplicates (via names and md5 hashing),
#' strip the file name of special characters, and note where the file originated.
#'
#' @name waitcopy
#' @docType package
NULL
