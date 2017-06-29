# running `Rscript -e "devtools::test()"` does NOT return
# an error code that will make gitlab-ci say the run failed
# R CMD check will, but then you have all the noise from
# check that may not be useful in the early stages of a package
# or analysis. This provides a method to capture that tests
# failed, and notify the CI runner to give the right status.
#
# capture results of running the test

#devtools::install()
library(methods)
test_res <- as.data.frame(devtools::test())

if (sum(test_res$error) > 0) {
  stop_code <- 1
} else if (sum(test_res$failed) > 0) {
  stop_code <- 1
} else if (sum(test_res$warning) > 0) {
  stop_code <- 1
} else {
  stop_code <- 0
}

q('no', stop_code, FALSE)
