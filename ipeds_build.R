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

filelist <-c("HD2015", "F1415_F1A", "F1415_F2", "SAL2015_IS", 
             "SAL2015_NIS", "EFFY2012", "EFFY2012", "EFFY2014", 
             "EFFY2015", "IC2012", "IC2012", "ADM2014", "ADM2015", 
             "EF2012A", "EF2012A", "EF2014A", "EF2015A", "EF2012B", 
             "EF2012B", "EF2014B", "EF2015B", "SFA1415", "SFA1314", 
             "SFA1213", "SFA1112", "GR2015")

# DOWNLOAD DATA AND SPSS SYNTAX ####

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

# READ-IN AND JOIN RELEVANT FILES ####

## First, take most recent year's IC Directory file as main table.####
ipeds_hd2015 <- read.csv("./data/hd2015.csv")

ipeds_hd2015$SECTOR <- factor(ipeds_hd2015$SECTOR,
                              levels=c(0:9,99),
                              labels=c('Administrative Unit',
                                       'Public, 4-year or above', 
                                       'Private not-for-profit, 4-year or above', 
                                       'Private for-profit, 4-year or above', 
                                       'Public, 2-year', 
                                       'Private not-for-profit, 2-year', 
                                       'Private for-profit, 2-year', 
                                       'Public, less-than 2-year', 
                                       'Private not-for-profit, less-than 2-year', 
                                       'Private for-profit, less-than 2-year', 
                                       'Sector unknown (not active)' 
                              ))

ipeds_hd2015$ICLEVEL <- factor(ipeds_hd2015$ICLEVEL,
                               levels=c(1,2,3,-3),
                               labels=c(
                                 'Four or more years', 
                                 'At least 2 but less than 4 years', 
                                 'Less than 2 years (below associate)',
                                 'Not available') 
)

ipeds_hd2015$CONTROL <- factor(ipeds_hd2015$CONTROL,
                               levels=c(1,2,3,-3),
                               labels=c(
                                 'Public', 
                                 'Private not-for-profit', 
                                 'Private for-profit', 
                                 '{Not available}'                                  
                               ))

ipeds_hd2015$HLOFFER <- factor(ipeds_hd2015$HLOFFER,
                               levels=c(1:9,-3),
                               labels=c(
                                 'Award of less than one academic year', 
                                 'At least 1, but less than 2 academic yrs', 
                                 'Associate^s degree', 
                                 'At least 2, but less than 4 academic yrs', 
                                 'Bachelor^s degree', 
                                 'Postbaccalaureate certificate', 
                                 'Master^s degree', 
                                 'Post-master^s certificate', 
                                 'Doctor^s degree', 
                                 '{Not available}'                                 
                               ))


###Subset to Public or PNP, granting a Bachelor's degree or higher
ipeds_hd2015 <- subset(ipeds_hd2015, CONTROL == "Public" | 
                         CONTROL == "Private not-for-profit")
ipeds_hd2015 <- subset(ipeds_hd2015, HLOFFER != "Award of less than one academic year" &
                         HLOFFER != "At least 1, but less than 2 academic yrs" & 
                         HLOFFER != "Associate^s degree" &
                         HLOFFER != "At least 2, but less than 4 academic yrs" )

##Check list of variables in Excel to drop
writeClipboard(colnames(ipeds_hd2015))
drop <-names(ipeds_hd2015) %in% c("X", "ADDR", "FIPS", "OBEREG", "CHFNM", "CHFTITLE", "GENTELE", "OPEFLAG", 
                                  "WEBADDR", "ADMINURL", "FAIDURL", "APPLURL", "NPRICURL", "VETURL", "ATHURL", 
                                  "C15BASIC", "C15IPUG", "C15IPGRD", "C15UGPRF", "C15ENPRF", "C15SZSET", 
                                  "CCBASIC", "CBSA", "CBSATYPE", "CSA", "NECTA", "F1SYSCOD", "COUNTYCD", 
                                  "COUNTYNM", "CNGDSTCD")

ipeds_hd2015 <- ipeds_hd2015[!drop]

## Enrollment Funnel ####

##2015 Funnel - adm2015 
adm2015 <- read.csv("./data/adm2015.csv")
adm2015$Applicants.2015 <- adm2015$APPLCN
adm2015$Admits.2015 <- adm2015$ADMSSN
adm2015$Enrolled.2015 <- adm2015$ENRLT
adm2015$SATVR25.2015 <- adm2015$SATVR25
adm2015$SATVR75.2015 <- adm2015$SATVR75
adm2015$SATMT25.2015 <- adm2015$SATMT25
adm2015$SATMT75.2015 <- adm2015$SATMT75
adm2015$ACTCM25.2015 <- adm2015$ACTCM25
adm2015$ACTCM75.2015 <- adm2015$ACTCM75
adm2015$AdmitRate.2015 <- adm2015$ADMSSN / adm2015$APPLCN
adm2015$Yield.2015 <-  adm2015$ENRLT / adm2015$ADMSSN 

writeClipboard(colnames(adm2015))

keep <-c("UNITID","Applicants.2015", "Admits.2015", "Enrolled.2015", "SATVR25.2015", "SATVR75.2015",
         "SATMT25.2015", "SATMT75.2015", "ACTCM25.2015", "ACTCM75.2015", "AdmitRate.2015", 
         "Yield.2015")

adm2015 <- adm2015[keep]

##2014 Funnel - adm2014 
adm2014 <- read.csv("./data/adm2014_rv.csv")
adm2014$Applicants.2014 <- adm2014$APPLCN
adm2014$Admits.2014 <- adm2014$ADMSSN
adm2014$Enrolled.2014 <- adm2014$ENRLT
adm2014$SATVR25.2014 <- adm2014$SATVR25
adm2014$SATVR75.2014 <- adm2014$SATVR75
adm2014$SATMT25.2014 <- adm2014$SATMT25
adm2014$SATMT75.2014 <- adm2014$SATMT75
adm2014$ACTCM25.2014 <- adm2014$ACTCM25
adm2014$ACTCM75.2014 <- adm2014$ACTCM75
adm2014$AdmitRate.2014 <- adm2014$ADMSSN / adm2014$APPLCN
adm2014$Yield.2014 <-  adm2014$ENRLT / adm2014$ADMSSN 

writeClipboard(colnames(adm2014))

keep <-c("UNITID","Applicants.2014", "Admits.2014", "Enrolled.2014", "SATVR25.2014", "SATVR75.2014",
         "SATMT25.2014", "SATMT75.2014", "ACTCM25.2014", "ACTCM75.2014", "AdmitRate.2014", 
         "Yield.2014")

adm2014 <- adm2014[keep]

##2013 Funnel - note, this comes in a different format from 14/15
ic2013 <- read.csv("./data/ic2013_rv.csv",stringsAsFactors = FALSE)
ic2013$Applicants.2013 <- as.numeric(ic2013$APPLCN)
ic2013$Admits.2013 <- as.numeric(ic2013$ADMSSN)
ic2013$Enrolled.2013 <- as.numeric(ic2013$ENRLT)
ic2013$SATVR25.2013 <- ic2013$SATVR25
ic2013$SATVR75.2013 <- ic2013$SATVR75
ic2013$SATMT25.2013 <- ic2013$SATMT25
ic2013$SATMT75.2013 <- ic2013$SATMT75
ic2013$ACTCM25.2013 <- ic2013$ACTCM25
ic2013$ACTCM75.2013 <- ic2013$ACTCM75
ic2013$AdmitRate.2013 <- ic2013$Admits.2013 / ic2013$Applicants.2013
ic2013$Yield.2013 <-  ic2013$Enrolled.2013 / ic2013$Admits.2013 

keep <-c("UNITID","Applicants.2013", "Admits.2013", "Enrolled.2013", "SATVR25.2013", "SATVR75.2013",
         "SATMT25.2013", "SATMT75.2013", "ACTCM25.2013", "ACTCM75.2013", "AdmitRate.2013", 
         "Yield.2013")

ic2013 <- ic2013[keep]

##2012 Funnel - note, this comes in a different format from 14/15
ic2012 <- read.csv("./data/ic2012_rv.csv",stringsAsFactors = FALSE)
ic2012$Applicants.2012 <- as.numeric(ic2012$APPLCN)
ic2012$Admits.2012 <- as.numeric(ic2012$ADMSSN)
ic2012$Enrolled.2012 <- as.numeric(ic2012$ENRLT)
ic2012$SATVR25.2012 <- ic2012$SATVR25
ic2012$SATVR75.2012 <- ic2012$SATVR75
ic2012$SATMT25.2012 <- ic2012$SATMT25
ic2012$SATMT75.2012 <- ic2012$SATMT75
ic2012$ACTCM25.2012 <- ic2012$ACTCM25
ic2012$ACTCM75.2012 <- ic2012$ACTCM75
ic2012$AdmitRate.2012 <- ic2012$Admits.2012 / ic2012$Applicants.2012
ic2012$Yield.2012 <-  ic2012$Enrolled.2012 / ic2012$Admits.2012 

keep <-c("UNITID","Applicants.2012", "Admits.2012", "Enrolled.2012", "SATVR25.2012", "SATVR75.2012",
         "SATMT25.2012", "SATMT75.2012", "ACTCM25.2012", "ACTCM75.2012", "AdmitRate.2012", 
         "Yield.2012")

ic2012 <- ic2012[keep]

############ JOIN TABLES ####
ipeds_full <- ipeds_hd2015
ipeds_full <- merge(ipeds_full,adm2015,by="UNITID")
ipeds_full <- merge(ipeds_full,adm2014,by="UNITID")
ipeds_full <- merge(ipeds_full,ic2013,by="UNITID")
ipeds_full <- merge(ipeds_full,ic2012,by="UNITID")

# END ####
