#
# Heatmap visualization of outlier ranks.
#
library("ggplot2")
suppressMessages(library("fields")) # for image.plot and tim.colors
# Enable debugging:
options(error =function(){print(sys.calls());print(warnings());q(status=1)}, keep.source=T)
source("scripts/shared.R")

# Plot column abbreviations
abbrev=list(KNN="A", KNNW="B", LOF="C", SimplifiedLOF="D", LoOP="E", LDOF="F", ODIN="G", KDEOS="H", COF="I", FastABOD="J", LDF="K", INFLO="L")

with.legend <- T

indir="outbins/*/*/*.rocauc.gz"
# Group filenames by their data set:
fnames = Sys.glob(indir)
#cat("Reading", length(fnames), "files.\n")

# Root-mean-square of standard deviations = root-mean of variance
avg_outlier_diversity <- function(x) {return(sqrt(mean(apply(x, 1, var))))}
# Maximum bin number
maxbin = 10

for (nam in fnames) {
  dat = read.csv(gzfile(nam),header=T,skip=1,sep=" ")
  # Remove the k value from the column name.
  names(dat) <- gsub("(\\.|-)[0-9]+$", "", names(dat))
  # Choose columns (and order) to plot
  cols <- c()
  for (alg in names(abbrev)) {
    if(!is.null(dat[[alg]]) && (alg %in% all.algorithms)) {
      cols <- c(cols, alg)
    }
  }
  stopifnot(length(cols) > 0)
  dat = dat[cols]
  # Output file name and folder
  nam <-  gsub("outbins/|\\.rocauc\\.gz","",nam)
  fname = paste0("plot/Heatmaps/", nam, ".pdf")
  if (!dir.exists(dirname(fname))) { dir.create(dirname(fname), recursive = T) }

  cat("Generating Heatmap for", fname, "\n")
  nam <-  gsub("(_norm|_withoutdupl|_idf|_[0-9]+|_v[0-9]+)*$","",nam)
  pdf(file=fname, width=ifelse(with.legend,7,5), height=ifelse(with.legend,5,4))
  par(oma=c(0,0,0,ifelse(with.legend,3,0)), mar=c(ifelse(with.legend,4,4),1,1,1), mgp=c(ifelse(with.legend,2,2),0,0))
  image(x=1:ncol(dat), z=t(dat), axes = T, yaxt='n', xaxt='n', xlab=basename(nam), col = tim.colors(maxbin), zlim=c(1,maxbin), cex.lab=ifelse(with.legend,1.2,2.)) #, mgp = c(2, 0, 0))#cex.lab=1.5, mgp = c(5, 0, 0))
  axis(1, at=1:ncol(dat), labels=abbrev[cols], tick=F, mgp = c(0, 0.5, 0), cex.axis=ifelse(with.legend,1.,1.4))
  if (with.legend) {
    par(oma=c(0,0,0,0))
    image.plot(z=t(dat), legend.only = TRUE, col = tim.colors(maxbin), zlim=c(1,maxbin), legend.mar=3.1, legend.cex=.5)
  }
  dev.off( )
}
