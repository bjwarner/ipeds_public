# IPEDS DATA - FILE READ IN AND BUILD
# Bijan Warner 7/4/2017
# https://github.com/bjwarner/ipeds_public
#
 setwd("~/R Projects/ipeds_build")

# Create functions to assist in downloading and building ####

###List files to download.
filelist <-c("EFFY2012","EFFY2013","EFFY2014","EFFY2015",
             "HD2015")

 
 

  
# Use list apply to run through list of file names,
# and for each folder, check to see if revised file exists.

lapply(filelist, function(ipedfile){
  urltemp <- paste0("https://nces.ed.gov/ipeds/datacenter/data/",
                    ipedfile,
                    ".zip")
  temp <-tempfile()
  download.file(urltemp,temp)
  tempdata <- read.csv(unz(temp,paste0(tolower(ipedfile),".csv")))
  write.csv(tempdata,paste0(tolower(ipedfile),".csv"))
  ##check if revised file exists
  if (paste0(tolower(ipedfile),"_rv.csv") %in% unzip(temp,list=TRUE)$Name) {
      tempdata_rv <- read.csv(unz(temp,paste0(tolower(ipedfile),"_rv.csv")))
      write.csv(tempdata_rv,paste0(tolower(ipedfile),"_rv.csv"))
  }
  unlink(temp)
})
  

# END ####