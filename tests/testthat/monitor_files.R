#!/usr/bin/Rscript
"Monitor directory of files for changes, log to a file

Usage: monitor_files.R [--directory=<use_dir> --logfile=<out_file> --time=time]

Options:
  -d --directory=<use_dir> the directory to use [default: .]
  -l --logfile=<out_file> the file to save changes [default: log_file.txt]
  -t --time=<time> how long to monitor the directory [default: 30]" -> doc

main <- function(directory = ".", logfile = "log_file.txt", time = 30){
  #print(directory)
  #print(logfile)
  #print(time)
  currtime <- Sys.time()

  nexttime <- Sys.time()

  file_info <- file.info(dir(directory, full.names = TRUE))
  file_info$check_time <- nexttime
  file_info$file <- row.names(file_info)
  write.table(file_info, row.names = FALSE, col.names = TRUE, file = logfile, sep = "\t")
  while (difftime(nexttime, currtime, units = "s") < time) {
    Sys.sleep(1)
    nexttime <- Sys.time()
    file_info2 <- file.info(dir(directory, full.names = TRUE))
    file_info2$check_time <- nexttime
    file_info2$file <- row.names(file_info2)
    file_info <- rbind(file_info, file_info2)
    write.table(file_info, row.names = FALSE, col.names = TRUE, file = logfile, sep = "\t")
  }

}
library(methods)
library(docopt)
opt <- docopt(doc)
#print(opt)

main(opt[["--directory"]], opt[["--logfile"]], as.numeric(opt[["--time"]]))
