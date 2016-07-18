#
#
# Plot per-dataset summaries.
#
suppressMessages(library("dplyr"))
library("ggplot2")
source("scripts/shared.R")
# Enable debugging:
options(error = function(){print(head(sys.calls(),-1));print(warnings());q(status=1)}, keep.source=T)

# Command line: 1. Input 2. Output folder, 3. Subset
args <- commandArgs(trailingOnly = TRUE)
infile <- args[1];
outdir <- args[2];

stopifnot(outdir != F)

##################
#Read in the data
##################
d_all=read.csv(gzfile(infile), check.names = TRUE)
#summary(d_all)
d_all$Name <- gsub("_withoutdupl", "", d_all$Name) #remove redundant part of the name
d_all$Name <- gsub("_norm", "", d_all$Name) #remove redundant part of the name
##################

for(level in levels(d_all$Algorithm)) {
  if (!(level %in% all.algorithms)) {
    cat("Droping unknown method from the data:", level, "\n");
    d_all = filter(d_all, Algorithm != level);
    #d_all = subset(d_all, Algorithm != level);
  }
}
d_all$Algorithm <- factor(d_all$Algorithm)
d_all$Name <- factor(d_all$Name)

#basic plot of Mean & SE, to be refined for different plot types
plotSummaryMeanAndSe <- function(data_summary, value, xlabel="", ylabel=""){
  plot=ggplot(data_summary, aes_string(x=value, y="mean"))
  plot = plot+geom_point()
  plot = plot+geom_errorbar(aes(ymin=mean-se, ymax=mean+se))
  plot = plot+labs(x=xlabel, y=ylabel)
  plot = plot+theme_bw()
  plot = plot+theme(panel.grid.major = element_line(size = 0.5, color = "grey"), panel.grid.minor = element_line(size = 0.2, color = "grey"))
  plot = plot+theme(axis.line = element_line(color = "black"))
  plot = plot+theme(axis.title=element_text(size=14))
  #plot = plot+theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5))
  return(plot)
}

############################################################################
#Characterize Datasets by best possible performance (best k, average sample)
############################################################################

plotForDataSet <- function(d, measure, ylabel, flip=T) {
  m = d[[measure]] # This will go by the name "m" below!
  bestPerDataset=aggregate(m~Name, data=d, max) #find max measure for each dataset
  bestPerDataset$Name=gsub("_v[0-9]+", "", bestPerDataset$Name) #remove version suffix in name for averaging samples
  # bestPerDataset_summary=ddply(bestPerDataset, c("Name"), summarize, N=length(m), mean=mean(m), sd=sd(m), se=sd/sqrt(N))
  bestPerDataset_summary <- bestPerDataset %>% group_by(Name) %>% summarize_each(funs(N=length, mean, sd, se=sd/sqrt(N)), m)

  plot=plotSummaryMeanAndSe(bestPerDataset_summary, "Name", ylabel=ylabel)
  #adjust plot
  if (flip) {
    plot = plot+theme(axis.text.x=element_text(angle=90, vjust = .5, hjust = 1))
  } else {
    plot = plot+coord_flip()
  }
  if(ylabel == "ROC AUC"){
    plot = plot+scale_y_continuous(limits=c(0.5,1),breaks=c(0.5, 0.63, 0.75, 0.88, 1.0))
  } else {
    plot = plot+scale_y_continuous(limits=c(0,1))
  }
  plot = plot+scale_x_discrete(limits=rev(bestPerDataset_summary$Name))
  return(plot)
}


if (!dir.exists(outdir)) { dir.create(outdir, recursive = T) }
lev <- levels(d_all$Name)
lev <- unique(gsub("_v[0-9]+", "", lev))
w <- (length(lev) + 3) %/% 6
cat(infile, ": NumData: ", length(lev), " suggested width: ", w)
w <- ifelse(grepl("literature", infile), 3, w)
w <- ifelse(grepl("semantic", infile), 8, w)
cat(" used width: ", w, "\n")
for (m in all.measures) {
  cat("Generating: ", m, "\n")
  plot = plotForDataSet(d_all, m, pretty(m))
  pdf(file=paste0(outdir, "/", m, ".pdf"), width=as.integer(w), height=4)
  print(plot)
  dev.off();
}
