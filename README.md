[![Last-changedate](https://img.shields.io/badge/last%20change-2017--06--15-brightgreen.svg)](https://github.com/rmflight/waitcopy/commits/master) [![CRAN\_Status\_Badge](https://www.r-pkg.org/badges/version/waitcopy)](https://cran.r-project.org/package=waitcopy) [![Travis-CI Build Status](https://travis-ci.org/rmflight/waitcopy.svg?branch=master)](https://travis-ci.org/rmflight/waitcopy) [![Coverage Status](https://img.shields.io/codecov/c/github/rmflight/waitcopy/master.svg)](https://codecov.io/github/rmflight/waitcopy?branch=master) [![Licence](https://img.shields.io/github/license/mashape/apistatus.svg)](http://choosealicense.com/licenses/mit/) [![ORCiD](https://img.shields.io/badge/orcid-0000--0001--8141--7788-green.svg)](http://orcid.org/0000-0001-8141-7788)

waitcopy
========

Copy files during particular times of day and with metadata.

Description
-----------

Provides the function `wait_copy` that:

-   will only copy files during a set time interval
-   will wait a specific amount of time between file copies
-   creates a json file with some limited meta-data about the file
-   removes special characters from the file name

### Why??

Imagine someone you work with has a hard drive that you need data from, but that hard drive is only accessible via the network, mounted via SAMBA, and there are potentially duplicate files with the same name, files with the same base name that are different, and the file path provides some meta-information about the sample. In addition, the file names have odd characters in them (spaces, colons, etc) that make them a pain to work with from the command line on Linux, so you'd prefer if they weren't there.

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

`devtools::install_github("rmflight/waitcopy")`

Example Metadata - List of Files
--------------------------------

    {
      [ 
        {
          "file" : "file1",
          "saved_path" : "local_path/file1",
          "original_path" : ["path1/file1", "path2/file1"],
          "md5" : "file1md5hash"
        },
        {
          "file" : "file2",
          "saved_path" : "local_path/file2",
          "original_path" : ["path1/file2"],
          "md5" : "file2md5hash"
        },
        {
          "file" : "file2-md5",
          "saved_path" : "local_path/file2-md5",
          "original_path" : ["path3/file2"],
          "md5" : "file2md5hash2"
        }
      ]
    }
