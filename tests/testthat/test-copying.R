context("copying")

# setup things in a random directory
create_in_temp <- function(dir_loc, create_it = TRUE) {
  temp_path <- tempfile(pattern = paste0("copyfiles-test-", dir_loc))
  if (create_it) {
    dir.create(temp_path)
  }
  temp_path
}
erase <- function(path) unlink(path, recursive = TRUE)

data("iris")

source_dir <- file.path(rprojroot::find_root("DESCRIPTION"), "tests", "testthat")

test_that("copying with duplicates works", {
  target_dir <- create_in_temp("target", FALSE)
  tmp_dir <- create_in_temp("temp")
  on.exit({
    erase(file.path(target_dir))
    erase(file.path(tmp_dir))
  })

  all_files <- dir(file.path(source_dir, c("set1", "set2")), pattern = "raw", full.names = TRUE)

  wait_copy(all_files, target_dir, json_meta = file.path(target_dir, "all_meta_data.json"),
                     tmp_loc = tmp_dir, time_limit = FALSE, pause_file = 0)

  json_metadata <- jsonlite::fromJSON(file.path(target_dir, "all_meta_data.json"), simplifyVector = FALSE)

  # 5 files, but one was a duplicate by md5
  expect_length(json_metadata, 4)

  expect_equal_to_reference(basename(json_metadata[[3]]$saved_path), "file2_dup")

  expect_length(json_metadata[[1]]$original_path, 2)


  new_files <- dir(file.path(source_dir, "set3"), pattern = "raw", full.names = TRUE)
  wait_copy(new_files, target_dir, json_meta = file.path(target_dir, "all_meta_data.json"),
                     tmp_loc = tmp_dir, time_limit = FALSE, pause_file = 0)

  meta_files <- dir(target_dir, pattern = "all_meta_data", full.names = TRUE)

  json_metadata2 <- jsonlite::fromJSON(file.path(target_dir, "all_meta_data.json"), simplifyVector = FALSE)
  expect_length(meta_files, 2)
  expect_length(json_metadata2, 6)
  expect_length(json_metadata2[[1]]$original_path, 3)

})

test_that("timings work", {
  target_dir2 <- create_in_temp("target2")
  tmp_dir2 <- create_in_temp("temp2")
  on.exit({
    erase(file.path(target_dir2))
    erase(file.path(tmp_dir2))
  })

  curr_time <- waitcopy:::get_now_in_local()
  curr_today <- waitcopy:::get_today_in_local()

  now_minus_today <- difftime(curr_time, curr_today, units = "s")
  beg_time <- seconds(now_minus_today + 20)
  end_time <- seconds(now_minus_today + 3600)

  expect_message(wait_copy(file.path(source_dir, "set1", "file1.raw"),
            target_dir2, json_meta = file.path(target_dir2, "all_meta_data.json"), tmp_loc = tmp_dir2,
            start_time = beg_time, stop_time = end_time,
            wait_check = 8),
            "Not allowed to copy yet")

  expect_true(file.exists(file.path(target_dir2, "file1.raw")))
  file_copy_date <- file.mtime(file.path(target_dir2, "file1.raw"))
  expect_true(difftime(file_copy_date, waitcopy:::get_today_in_local() + beg_time) > 0)

  now_minus_today <- difftime(curr_time, curr_today, units = "s")
  beg_time <- seconds(now_minus_today + 50)
  end_time <- seconds(now_minus_today + 3600)

  expect_message(wait_copy(file.path(source_dir, "set1", "file2.raw"),
                           target_dir2, json_meta = file.path(target_dir2, "all_meta_data.json"),
                           tmp_loc = tmp_dir2,
                           start_time = beg_time, stop_time = end_time,
                           wait_check = 2, n_check = 2),
                 "Reached maximum number of wait periods")

  now_minus_today <- difftime(curr_time, curr_today, units = "s")
  beg_time <- seconds(now_minus_today)
  end_time <- seconds(now_minus_today + 3600)

  all_files <- dir(file.path(source_dir, c("set1", "set2")), pattern = "raw", full.names = TRUE)[2:3]

  expect_message(wait_copy(all_files,
                           target_dir2, json_meta = file.path(target_dir2, "all_meta_data.json"),
                           tmp_loc = tmp_dir2,
                           start_time = beg_time, stop_time = end_time,
                           wait_files = 1, pause_wait = 2),
                 "Waiting between sets of files")
})

test_that("warnings appear", {
  check_files <- dir(file.path(source_dir, c("set1", "set2")), full.names = TRUE)
  expect_silent(check_files_exist(check_files))

  check_files <- c(check_files, file.path(source_dir, "idontexist.raw"))
  expect_warning(check_files_exist(check_files), "file list do not exist!")

})


test_that("copy before waiting", {
  skip_on_cran()
  file.create("target_dir3/dummy")
  system("Rscript monitor_files.R -d target_dir3 -l log_file.txt -t 40", intern = FALSE, wait = FALSE)
  Sys.sleep(4)
  has_log_file <- file.exists("log_file.txt")

  skip_if_not(has_log_file)
  #dir.create("target_dir3")
  tmp_dir3 <- create_in_temp("temp3")

  on.exit({
    erase(grep("dummy", dir(file.path("target_dir3"), full.names = TRUE), invert = TRUE, value = TRUE))
    erase(file.path(tmp_dir3))
    erase("log_file.txt")
  })

  curr_time <- waitcopy:::get_now_in_local()
  curr_time2 <- Sys.time()
  curr_today <- waitcopy:::get_today_in_local()

  now_minus_today <- difftime(curr_time, curr_today, units = "s")
  beg_time <- seconds(now_minus_today + 4)
  end_time <- seconds(now_minus_today + 10)

  all_files <- dir(file.path(source_dir, c("set1", "set2")), pattern = "raw", full.names = TRUE)[2:3]

  wait_copy(all_files,
            "target_dir3", json_meta = file.path("target_dir3", "all_meta_data.json"), tmp_loc = tmp_dir3,
            start_time = beg_time, stop_time = end_time,
            wait_check = 4, n_check = 2,
            wait_files = 1, pause_wait = 10)

  # browser(expr = TRUE)

  log_data <- read.table("log_file.txt", header = TRUE, sep = "\t", stringsAsFactors = FALSE)

  log_data <- dplyr::filter(log_data, grepl("target_dir3/all_meta_data.json", file))
  #log_data$check_time <- NULL

  mtimes <- unique(log_data$mtime)

  #browser(expr = TRUE)
  Sys.sleep(20)
  has_2_mtime <- length(mtimes) == 2
  skip_if_not(has_2_mtime)
  expect_equal(length(mtimes), 2)
  expect_gt(as.numeric(difftime(mtimes[1], curr_time2, units = "s")), 14)
  expect_gt(as.numeric(difftime(mtimes[2], curr_time2, units = "s")), 18)


})
