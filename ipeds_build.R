# IPEDS DATA - FILE READ IN AND BUILD
# Bijan Warner 7/4/2017
# https://github.com/bjwarner/ipeds_public
#
# setwd("~/R Projects/ipeds_build")

### NCES IPEDS files available for manual download here:
# https://nces.ed.gov/ipeds/datacenter/DataFiles.aspx


###List files to download.
# For most recent year (2015 as of 7/4/2017), also download:
# Directory, grad rate, GASB/FASB finance files

filelist <-c("EFFY2012","EFFY2013","EFFY2014","EFFY2015",
             "IC2012","IC2013","ADM2014","ADM2015",
             "EF2012A","EF2013A","EF2014A","EF2015A",
             "EF2012B","EF2013B","EF2014B","EF2015B")



# Use list apply to run through list of file names,
# and for each folder, check to see if revised file exists (denoted with "_rv").

lapply(filelist, function(ipedfile){
  urltemp <- paste0("https://nces.ed.gov/ipeds/datacenter/data/",
                    ipedfile,
                    ".zip")
  temp <-tempfile()
  download.file(urltemp,temp)
  tempdata <- read.csv(unz(temp,paste0(tolower(ipedfile),".csv")))
  
  #revise location path (create first)
  write.csv(tempdata,paste0("./data/",tolower(ipedfile),".csv"))
  
  ##check if revised file exists
  if (paste0(tolower(ipedfile),"_rv.csv") %in% unzip(temp,list=TRUE)$Name) {
    tempdata_rv <- read.csv(unz(temp,paste0(tolower(ipedfile),"_rv.csv")))
    write.csv(tempdata_rv,paste0("./data/",tolower(ipedfile),"_rv.csv"))
  }
  unlink(temp)
})


# Now download .sps files for variable names and values.
#Convention is to append "_SPS.zip" for read in files.
#filelist_sps <- lapply(filelist,paste0,"_SPS")

lapply(filelist, function(spsfile){
  urltemp <- paste0("https://nces.ed.gov/ipeds/datacenter/data/",
                    spsfile,
                    "_SPS.zip")
  temp <-tempfile()
  download.file(urltemp,temp)
  fileConn<-unz(temp,paste0(tolower(spsfile),".sps"))
  text_sps <- readChar(fileConn,nchars=1000000)
  
  #note, need to eliminate duplicate line returns "\r\n"
  text_sps <- gsub("\r\n","\r",text_sps)
  
  #create syntax sub-folder before running
  savConn<-file(paste0("./syntax/",tolower(spsfile),".sps"))
  writeLines(text_sps,savConn)
  close(fileConn)
  close(savConn)
  unlink(temp)
}
)



# END ####
