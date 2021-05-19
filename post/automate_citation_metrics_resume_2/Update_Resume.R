#############################
# Install and Load Packages #
#############################

if(! require("knitr")) install.packages("knitr", repos='http://cran.us.r-project.org')
if(! require("tinytex")) install.packages("tinytex", repos='http://cran.us.r-project.org')
library(knitr)
library(tinytex)
tinytex::install_tinytex() 

#######################################
# Update Citation Metrics in Document #
#######################################

Sweave2knitr("Resume_Master.Rnw")
knit2pdf("Resume_Master-knitr.Rnw", output = "Resume_Final.tex", compiler = 'pdflatex')
tinytex::pdflatex('Resume_Final.tex')
