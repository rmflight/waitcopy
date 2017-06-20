source_dir <- file.path(rprojroot::find_root("DESCRIPTION"), "tests", "testthat")

# create some data to work with
dir.create(file.path(source_dir, "set1"))
# two completely different files
dput(iris[, -1], file = file.path(source_dir, "set1", "file1.raw"))
dput(iris[, -3], file = file.path(source_dir, "set1", "file2.raw"))

# and a duplicate in the same directory
dput(iris[, -1], file = file.path(source_dir, "set1", "file3.raw")) # duplicate of file1

dir.create(file.path(source_dir, "set2"))

dput(iris[-10, ], file = file.path(source_dir, "set2", "file4.raw"))
dput(iris[-3, ], file = file.path(source_dir, "set2", "file2.raw"))

# add creating backup and then copy a couple more files
dir.create(file.path(source_dir, "set3"))
dput(iris[, -1], file = file.path(source_dir, "set3", "file5.raw"))
dput(iris[-120, ], file = file.path(source_dir, "set3", "file6.raw"))
dput(iris[, -2], file = file.path(source_dir, "set3", "file7.raw"))
