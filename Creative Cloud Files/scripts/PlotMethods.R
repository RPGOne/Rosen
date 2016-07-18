#
# Boxplot the performance of each algorithm, averaged for each group of data sets
#
# This produces one plot per measure.
#
suppressMessages(library("dplyr"))
library("ggplot2")
source("scripts/shared.R")
# Enable debugging:
options(error = function(){print(head(sys.calls(),-1));print(warnings());q(status=1)}, keep.source=T)

# Command line: 1. Input 2. Output folder, 3. Subset
args <- commandArgs(trailingOnly = TRUE)
infile <- args[1]
subset <- args[2] # MUST match the input file!
outdir <- args[3]

limitroc <- F # Publication version uses a smaller range for ROC AUC

stopifnot(outdir != F)

##################
#Read in the data
##################
d_all <- read.csv(gzfile(infile), check.names = TRUE)
d_all$Name <- gsub("_withoutdupl", "", d_all$Name) #remove redundant part of the name
d_all$Name <- gsub("_norm", "", d_all$Name) #remove redundant part of the name
##################

for(level in levels(d_all$Algorithm)) {
  if (!(level %in% all.algorithms)) {
    cat("Droping unknown method from the data:", level, "\n");
    d_all = filter(d_all, Algorithm != level);
  }
}
d_all$Algorithm <- factor(d_all$Algorithm)

###########################################################
#Characterize Methods
###########################################################

plotSummaryDataWrtMethods <- function(ds, measure, value, xlabel="", ylabel="") {
  stopifnot(nrow(ds) > 0)
  # First, aggregate over all k (per Name and Algorithm)
  summary <- ds %>% group_by(Name, Algorithm) %>% summarize_each_(funs(mean), measure)
  # Second, aggregate over all Name (per Algorithm)
  summary <- summary %>% group_by(Algorithm) %>% summarize_each_(funs(N=length, mean, sd, se=sd/sqrt(N)), measure)

  # Reorder algorithms (from shared.R)
  summary$plot_order <- reorder.algorithms(levels(summary$Algorithm))
  summary$Algorithm <- factor(summary$Algorithm, levels = summary$Algorithm[order(summary$plot_order)])

  plot = ggplot(summary, aes_string(x=value, y="mean"))
  plot = plot+geom_point()
  plot = plot+geom_errorbar(aes(ymin=mean-se, ymax=mean+se))
  plot = plot+labs(x=xlabel, y=ylabel)
  plot = plot+theme_bw()
  plot = plot+theme(panel.grid.major = element_line(size = 0.5, color = "grey"), panel.grid.minor = element_line(size = 0.2, color = "grey"))
  plot = plot+theme(axis.line = element_line(color = "black"))
  plot = plot+theme(axis.title=element_text(size=14))

  l <- 0.0
  u <- 1.0
  if (measure == "ROC.AUC") {
    l = ifelse(limitroc, 0.65, 0.5)
    u = ifelse(limitroc, 0.86, 1.0)
  }
  plot = plot + theme(axis.text.x=element_text(angle=90, vjust = 0.5))
  plot = plot + scale_y_continuous(limits = c(l, u))
  return(plot)
}

for (m in all.measures) {
  labelY="mean PRETTYNAME (mean over SUBSET per data set)"
  labelY=gsub("PRETTYNAME", pretty(m), labelY)
  labelY=gsub("SUBSET", subset, labelY)
  cat("Generating", labelY, "\n")
  d = outdir #paste0(outdir, "/", m, "/")
  if (!dir.exists(d)) { dir.create(d, recursive = T) }
  pdfname=paste0(d, "/", m, ".pdf")
  plot = plotSummaryDataWrtMethods(d_all, m, "Algorithm", ylabel=labelY)
  ggsave(pdfname, plot, width=5, height=8)
}
