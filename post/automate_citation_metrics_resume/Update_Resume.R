#############################
# Install and Load Packages #
#############################

if(! require("officer")) install.packages("officer", repos='http://cran.us.r-project.org')
if(! require("scholar")) install.packages("scholar", repos='http://cran.us.r-project.org')
library(officer)
library(scholar)

####################################
# Calculate Google Scholar Metrics #
####################################

my_Google_Scholar<-get_profile('twbXG-wAAAAJ')
a<-as.character(my_Google_Scholar$total_cites)
b<-as.character(my_Google_Scholar$h_index)
c<-as.character(my_Google_Scholar$i10_index)

#######################################
# Update Citation Metrics in Document #
#######################################

doc <- read_docx('Resume_Master.docx')
body_replace_text_at_bkm(doc, 'GS_a', a)
body_replace_text_at_bkm(doc, 'GS_b', b)
body_replace_text_at_bkm(doc, 'GS_c', c)
print(doc, target = "Resume_Final.docx")