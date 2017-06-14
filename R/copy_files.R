#' rename a file
#'
#' given a file to copy, generates a new file name stripped of special
#' characters
#'
#' @param in_file the file to copy
#' @param replace_special what to use to replace anything besides dot
#'
#' @details This function creates a new file name that is stripped of special
#' characters. The following characters are replaced by a period: " ", ":", "~",
#' "'". A leading "~" will be replaced by space.
#'
#' @import magrittr
#'
#' @export
#'
#' @return character
rename_file <- function(in_file, replace_special = "-"){
  use_file <- basename(in_file)

  file_name <- basename(use_file) %>%
    gsub(" ", replace_special, ., fixed = TRUE) %>%
    gsub(":", replace_special, ., fixed = TRUE) %>%
    gsub("^~", "", .) %>%
    gsub("~", replace_special, ., fixed = TRUE) %>%
    gsub("'", replace_special, ., fixed = TRUE)

  file_name
}

#' copy file
#'
#' Copy a single file from one location to another
#'
#' @param from_file the location of the original file
#' @param to_dir the location to copy the file to
#' @param json_data the json meta information data
#' @param tmp_loc temp location if you want to specify it
#'
#' @details We want to keep track of information about the copied files, so this
#' function does some stuff to help us out. It strips special characters from
#' the base file name, copies the file to a temp location, calculates the MD5 hash
#' of the file, checks the JSON meta file for matches to the MD5, and if there
#' are none, copies the renamed file to the copy location.
#'
#' If a matching instance of MD5 hashes are found, then the file path is added
#' to the entry for that file location.
#'
#' If a matching file name is found but with a different MD5 hash, then the first
#' 8 characters of the MD5 hash are appended to the file, and it is added to the
#' database.
#'
#' @import digest
#' @importFrom tools file_ext
#' @importFrom purrr map_lgl
#'
#' @export
#' @return list
#'
copy_file <- function(from_file = NULL, to_dir = ".", json_data = NULL, tmp_loc = "/tmp"){
  stopifnot(!is.null(from_file))

  to_dir <- normalizePath(to_dir)

  if (!dir.exists(to_dir)) {
    dir.create(to_dir)
  }

  base_file <- basename(from_file)
  base_out <- rename_file(base_file)

  tmp_file <- file.path(tmp_loc, base_out)

  did_copy <- file.copy(from_file, tmp_file)

  if (did_copy) {
    add_file <- TRUE
    md5 <- digest(tmp_file, algo = "md5", file = TRUE)
    if (!is.null(json_data)) {
      match_md5 <- map_lgl(json_data, function(x){md5 %in% x$md5})
      match_file <- map_lgl(json_data, function(x){base_file %in% basename(unlist(x$original_path))})
    } else {
      match_md5 <- FALSE
      match_file <- FALSE
    }

    if (any(match_md5)) {
      #browser(expr = TRUE)
      tmp_json <- json_data[[which(match_md5)]]

      # figure out where the individual json file should be saved
      raw_path <- tmp_json$saved_path
      json_path <- replace_file_extension(raw_path, ".json")

      tmp_json[["original_path"]] <- c(tmp_json[["original_path"]], from_file)

      save_json(tmp_json, json_path)

      json_data[[which(match_md5)]] <- tmp_json

      add_file <- FALSE
    } else if (any(match_file)) {
      fileext <- tools::file_ext(base_out)
      fileext_regex <- paste0(".", fileext, "$")
      base2 <- gsub(fileext_regex, "", base_out)
      base_out <- paste0(base2, "-", substr(md5, 1, 8), ".", fileext)
    }

    if (add_file) {
      file_loc <- file.path(to_dir, base_out)
      did_copy2 <- file.copy(tmp_file, file_loc)
      if (did_copy2) {
        file_data <- vector("list", 1)
        file_data[[1]] <- list(
          file = base_out,
          saved_path = file_loc,
          original_path = from_file,
          md5 = md5
        )
        json_path <- replace_file_extension(file_loc, ".json")
        save_json(file_data, json_path)
        if (is.null(json_data)) {
          json_data <- file_data
        } else {
          json_data <- c(json_data, file_data)
        }
      }

    }
    unlink(tmp_file)
  }

  json_data

}

#' convert to another format
#'
#' given a file path, replace a files extension with a new one
#'
#' @param in_file the file name to work with
#' @param out_extension the new file extension
#'
#' @noRd
replace_file_extension <- function(in_file, out_extension){

  fileext <- tools::file_ext(in_file)
  fileext_regex <- paste0(".", fileext, "$")
  new_file <- gsub(fileext_regex, out_extension, in_file)
  new_file
}

#' save json
#'
#' given a list, saves it to json in a nice way
#'
#' @param list_data the data in list format
#' @param save_loc the location to save it to
#'
#' @noRd
save_json <- function(list_data, save_loc){
  cat(jsonlite::toJSON(list_data, pretty = TRUE, auto_unbox = TRUE), file = save_loc, append = FALSE)
}

#' wait copy
#'
#' Copy files from one location to another, during set hours if desired. This
#' is very useful for copying from networked drives that get a lot of activity
#' during the day.
#'
#' @param file_list a character vector of files to copy from
#' @param to_dir where to copy the files to
#' @param json_meta the json meta flat file
#' @param tmp_loc a temp file location
#' @param time_limit only copy during a certain time?
#' @param start_time when to start copying
#' @param stop_time when to stop copying
#' @param time_zone what time zone are we in
#' @param wait_check how long to wait before checking again
#' @param n_check how many times to try before giving up
#' @param wait_files how many files before pausing
#' @param pause_wait how long to pause when the wait limit is reached
#' @param pause_file how long to pause between every file
#'
#' @details
#' 1. **Limiting by time of day**: if `time_limit = TRUE`, the `start_time` and
#'   `stop_time` are assumed to be on a
#'   per day basis, so they should be encoded as the number of hours from midnight.
#'   The function actually does a periodic check as to whether the
#'   `start_time` is ahead of it, and if it is not, then it will create
#'   a new time interval for the copying to be allowed. Default is from 8pm (20:00)
#'   to 6am (30:00). The `wait_check` parameter sets how often to wait before checking
#'   the time again (default is 1800 seconds / 30 minutes), and `n_check` parameter
#'   defines how many times to check if the copying can be done (defaults to infinite).
#' 1. **Time Zone**: Provide your time zone so that the time functionality works
#'   properly!
#' 1. **Waiting Between Copies**: In addition to only copying between certain hours,
#'   it is possible to set how long to pause between each file using `pause_file`,
#'   default is 2 seconds, and also a longer interval after copying several files
#'   using `wait_files` (10 files) and `pause_wait` (10 seconds).
#'
#' @import lubridate
#' @importFrom jsonlite fromJSON
#' @importFrom purrr map_chr map
#'
#' @return logical
#' @export
wait_copy <- function(file_list, to_dir = ".",
                               json_meta = "all_meta_data.json",
                               tmp_loc = "/tmp",
                               time_limit = TRUE,
                               start_time = hours(20), stop_time = hours(30),
                               time_zone = "EST", wait_check = 1800, n_check = Inf,
                               wait_files = 10, pause_wait = 10,
                               pause_file = 2){

  if (file.exists(json_meta)) {
    backup_name <- gsub(".json", paste0("-", gsub(" ", "-", as.character(Sys.time())), ".json"), json_meta)
    file.copy(json_meta, backup_name)
    json_data <- jsonlite::fromJSON(json_meta, simplifyVector = FALSE)
  } else {
    json_data <- NULL
  }

  # check if we've copied some before, and if so we want to remove them so
  # we don't waste time copying them again.
  if (!(length(json_data) == 0)) {
    #browser()
    previous_files <- unlist(map(json_data, function(x){x$original_path}))

    file_list <- file_list[!(file_list %in% previous_files)]
  }


  if (time_limit) {
    t_start <- today() + start_time
    t_stop <- today() + stop_time
  } else {
    t_start <- today() - days(10)
    t_stop <- today() + days(10)
  }
  tz(t_start) <- time_zone
  tz(t_stop) <- time_zone
  allowed_copy_time <- interval(t_start, t_stop, tz(t_stop))

  # check that the top level directory we are copying from and to
  # actually exists so that we don't try to copy from an invalid location


  to_copy <- length(file_list)
  check_wait_counter <- 0
  i_check <- 0
  did_copy <- 1
  while (did_copy <= to_copy) {
    now1 <- now()
    now2 <- now()
    tmp_int <- interval(now1, now2)
    can_copy <- int_overlaps(tmp_int, allowed_copy_time)

    if (can_copy) {
      # copy if we're below the limit for waiting for a time,
      # otherwise, wait for a time. Used to keep us in check on the server
      # and wait some time after copying a reasonable number of files.
      # Note that we also pause a little bit of time after each copy.
      if (check_wait_counter < wait_files) {
        json_data <- copy_file(file_list[did_copy], to_dir, json_data, tmp_loc)

        Sys.sleep(pause_file)
        check_wait_counter <- check_wait_counter + 1
        did_copy <- did_copy + 1

      } else {
        Sys.sleep(pause_wait)
        #message("sleeping for a longer time!")
        check_wait_counter <- 0
      }

    } else {
      # if we're not allowed, wait some time before trying again.
      message(paste0("Not allowed to copy yet, waiting! .... ", Sys.time()))
      i_check <- i_check + 1
      if (i_check <= n_check) {
        Sys.sleep(wait_check)
      } else {
        message("Reached maximum number of wait periods, exiting ....")
        break()
      }

    }
  }
  save_json(json_data, json_meta)
}

