[![Last-changedate](https://img.shields.io/badge/last%20change-2017--06--29-brightgreen.svg)](https://github.com/rmflight/waitcopy/commits/master) [![CRAN\_Status\_Badge](https://www.r-pkg.org/badges/version/waitcopy)](https://cran.r-project.org/package=waitcopy) [![Travis-CI Build Status](https://travis-ci.org/rmflight/waitcopy.svg?branch=master)](https://travis-ci.org/rmflight/waitcopy) [![Coverage Status](https://img.shields.io/codecov/c/github/rmflight/waitcopy/master.svg)](https://codecov.io/github/rmflight/waitcopy?branch=master) [![Licence](https://img.shields.io/github/license/mashape/apistatus.svg)](http://choosealicense.com/licenses/mit/) [![ORCiD](https://img.shields.io/badge/orcid-0000--0001--8141--7788-green.svg)](http://orcid.org/0000-0001-8141-7788)

waitcopy
========

Copy files during particular times of day and with metadata.

Useful Definitions
------------------

-   **filepath**: the full path to a given file, eg /home/user/file1.png
-   **basename**: the actual filename of a file path, eg file1.png in /home/user/file1.png
-   **dirname**: the directory portion of a filepath, eg /home/user in /home/user/file1.png

Description
-----------

Provides the function `wait_copy` that:

-   will only copy files during a set time interval
-   will wait a specific amount of time between file copies
-   creates a json file with some limited meta-data about the file
-   removes special characters from the file name

### Why??

Imagine someone you work with has a hard drive that you need data from, but that hard drive is only accessible via the network, mounted via SAMBA, and there are potentially duplicate files with the file or base name, files with the same file name that are different, and the file path provides some meta-information about the sample. In addition, the file names have odd characters in them (spaces, colons, etc) that make them a pain to work with from the command line on Linux, so you'd prefer if they weren't there.

The files are small, so even copying over the network is fast, but if you copy too many too quickly during the day, you'll get complaints about hitting this shared resource too often by the people who are local to it.

### The Solution

So ideally, you want to copy the files only during certain hours, wait a little bit between each copy operation, check for duplicates (via names and md5 hashing), strip the file name of special characters, and note where the file originated.

`waitcopy` provides these capabilities.

How it Works
------------

Given a file to copy, and a location to copy it to, does a few things:

-   strip special characters and spaces from the file name (if asked)
-   copy the file to a temp location
-   save the original path to the file it was being copied from
-   calculate the MD5 hash of the file
-   check master json data of MD5 hashes and file names
-   if MD5 is new, add the new file name, original file path, and MD5 to the master json file
-   if MD5 is not new, **add** the original file path to the matching file entry in the master json file.
-   if a matching file name is found but with a different MD5 hash, append the first 8 digits of the MD5 hash to the file name, and add it to the json data

Installation
------------

### Stable Version

``` r
# install.packages("devtools")
devtools::install_github("MoseleyBioinformaticsLab/waitcopy")
```

### Development Version

``` r
# install.packages("devtools")
devtools::install_github("rmflight/waitcopy")
```

Example Usage
-------------

### Worked Example

Lets imagine that we want to copy a set of files during a set time, and one of the files is duplicated (but we don't know that before we start).

``` r
library(waitcopy)
library(lubridate)
```

    ## 
    ## Attaching package: 'lubridate'

    ## The following object is masked from 'package:base':
    ## 
    ##     date

``` r
# files are in the extdata directory of waitcopy
testloc <- system.file("extdata", "set1", package = "waitcopy")

file_list <- dir(testloc, pattern = "raw", full.names = TRUE)
file_list
```

    ## [1] "/software/R_libs/R340_bioc35/waitcopy/extdata/set1/file1.raw"
    ## [2] "/software/R_libs/R340_bioc35/waitcopy/extdata/set1/file2.raw"
    ## [3] "/software/R_libs/R340_bioc35/waitcopy/extdata/set1/file3.raw"

We will setup a **temp** directory to copy them to:

``` r
temp_dir <- tempfile(pattern = "copyfiles-test-1")
dir.create(temp_dir)
dir(temp_dir)
```

    ## character(0)

And then lets set up to copy **20s** from now.

``` r
curr_time <- waitcopy:::get_now_in_local()
curr_today <- waitcopy:::get_today_in_local()

now_minus_today <- difftime(curr_time, curr_today, units = "s")
beg_time <- seconds(now_minus_today + 20)
end_time <- seconds(now_minus_today + 3600)

beg_time
```

    ## [1] "58278.6133356094S"

``` r
end_time
```

    ## [1] "61858.6133356094S"

And now let's copy! This is in the **near** future, so we will set the `wait_check` parameter to a low value of only 10 seconds, normally this is set to 30 minutes (1800 seconds), assuming that it is in the far future when you want to copy the files.

``` r
wait_copy(file_list, temp_dir, json_meta = file.path(temp_dir, "all_meta.json"),
          start_time = beg_time, stop_time = end_time, wait_check = 10, pause_file = 0)
```

    ## Not allowed to copy yet, waiting! .... 2017-06-29 16:10:59

    ## Not allowed to copy yet, waiting! .... 2017-06-29 16:11:09

Lets look at how many files were copied and the contents of the JSON metadata.

``` r
copied_files <- dir(temp_dir)
copied_files
```

    ## [1] "all_meta.json" "file1.json"    "file1.raw"     "file2.json"   
    ## [5] "file2.raw"

``` r
meta_json <- jsonlite::fromJSON(file.path(temp_dir, "all_meta.json"), simplifyVector = FALSE)
jsonlite::toJSON(meta_json, auto_unbox = TRUE, pretty = TRUE)
```

    ## [
    ##   {
    ##     "file": "file1.raw",
    ##     "saved_path": "/tmp/RtmpF3p4GH/copyfiles-test-122ba73a7b51/file1.raw",
    ##     "original_path": [
    ##       "/software/R_libs/R340_bioc35/waitcopy/extdata/set1/file1.raw",
    ##       "/software/R_libs/R340_bioc35/waitcopy/extdata/set1/file3.raw"
    ##     ],
    ##     "md5": "8d32638742fe7daad39765205aa5120a"
    ##   },
    ##   {
    ##     "file": "file2.raw",
    ##     "saved_path": "/tmp/RtmpF3p4GH/copyfiles-test-122ba73a7b51/file2.raw",
    ##     "original_path": "/software/R_libs/R340_bioc35/waitcopy/extdata/set1/file2.raw",
    ##     "md5": "dbd76b5cc6d105c8fe077c30887c1389"
    ##   }
    ## ]

### Alternatives (not run)

#### Default

If you just want to copy between 8pm and 6am everyday for however long it will take:

``` r
wait_copy(file_list, temp_dir, json_meta = file.path(temp_dir, "all_meta.json"))
```

#### Change Start or End Time in Hours

What if the best time to copy files was from 10am until 1pm (13:00)??

``` r
wait_copy(file_list, temp_dir, json_meta = file.path(temp_dir, "all_meta.json"),
start_time = hours(10), stop_time = hours(13))
```

#### Don't Set a Time Limit

``` r
wait_copy(file_list, temp_dir, json_meta = file.path(temp_dir, "all_meta.json"),
time_limit = FALSE)
```

#### Stop Checking The Time

If you want the function to give up after trying to check the time, then change the `n_check` variable. If you wanted to stop checking after 3 tries:

``` r
wait_copy(file_list, temp_dir, json_meta = file.path(temp_dir, "all_meta.json"),
n_check = 3)
```

#### Use Different Renaming Function

An alternative way to handle nasty file names would be to use the `make.names` function:

``` r
wait_copy(file_list, temp_dir, json_meta = file.path(temp_dir, "all_meta.json"),
clean_file_fun = make.names)
```

Note that this is only applied to the `basename` of the file path, i.e. the actual file-name after removing the path in front of the file-name.
