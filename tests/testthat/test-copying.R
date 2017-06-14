context("copying")

# setup things in a random directory
create_in_temp <- function(dir_loc) {
  temp_path <- tempfile(pattern = paste0("copyfiles-test-", dir_loc))
  dir.create(temp_path)
  temp_path
}
erase <- function(path) unlink(path, recursive = TRUE)

data("iris")

test_that("copying with duplicates works", {
  source_dir <- create_in_temp("source")
  target_dir <- create_in_temp("target")
  tmp_dir <- create_in_temp("temp")
  on.exit({
    erase(file.path(source_dir));
    erase(file.path(target_dir));
    erase(file.path(tmp_dir))
  })

  # create some data to work with
  dir.create(file.path(source_dir, "set1"))
  # two completely different files
  dput(iris[, -1], file = file.path(source_dir, "set1", "file1.raw"))
  dput(iris[, -3], file = file.path(source_dir, "set1", "file2.raw"))

  # and a duplicate in the same directory
  dput(iris[, -1], file = file.path(source_dir, "set1", "file3.raw"))

  dir.create(file.path(source_dir, "set2"))

  dput(iris[-10, ], file = file.path(source_dir, "set2", "file4.raw"))
  dput(iris[-3, ], file = file.path(source_dir, "set2", "file2.raw"))

  all_files <- dir(source_dir, pattern = "raw", full.names = TRUE, recursive = TRUE)

  wait_copy(all_files, target_dir, json_meta = file.path(target_dir, "all_meta_data.json"),
                     tmp_loc = tmp_dir, time_limit = FALSE, pause_file = 0)

  json_metadata <- jsonlite::fromJSON(file.path(target_dir, "all_meta_data.json"), simplifyVector = FALSE)

  # 5 files, but one was a duplicate by md5
  expect_length(json_metadata, 4)

  expect_equal_to_reference(basename(json_metadata[[3]]$saved_path), "file2_dup")

  expect_length(json_metadata[[1]]$original_path, 2)

  # add creating backup and then copy a couple more files
  dir.create(file.path(source_dir, "set3"))
  dput(iris[, -1], file = file.path(source_dir, "set3", "file5.raw"))
  dput(iris[-120, ], file = file.path(source_dir, "set3", "file6.raw"))
  dput(iris[, -2], file = file.path(source_dir, "set3", "file7.raw"))

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
  source_dir2 <- create_in_temp("source2")
  target_dir2 <- create_in_temp("target2")
  tmp_dir2 <- create_in_temp("temp2")
  on.exit({
    erase(file.path(source_dir2));
    erase(file.path(target_dir2));
    erase(file.path(tmp_dir2))
  })

  dir.create(file.path(source_dir2, "set_timing"))
  dput(iris[-1, ], file = file.path(source_dir2, "set_timing", "file1_timing.raw"))

  curr_time <- waitcopy:::get_now_in_local()
  curr_today <- waitcopy:::get_today_in_local()

  now_minus_today <- difftime(curr_time, curr_today, units = "s")
  beg_time <- seconds(now_minus_today + 20)
  end_time <- seconds(now_minus_today + 3600)

  wait_copy(file.path(source_dir2, "set_timing", "file1_timing.raw"),
            target_dir2, json_meta = file.path(target_dir2, "all_meta_data.json"), tmp_loc = tmp_dir2,
            start_time = beg_time, stop_time = end_time,
            wait_check = 8)

  expect_true(file.exists(file.path(target_dir2, "file1_timing.raw")))
  file_copy_date <- file.mtime(file.path(target_dir2, "file1_timing.raw"))
  expect_true(difftime(file_copy_date, waitcopy:::get_today_in_local() + beg_time) > 0)


})
