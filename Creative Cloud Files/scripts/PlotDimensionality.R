#
# Plot the dimensionality plot, to demonstrate that there is no obivous correlation
# between dimensionality and difficulty.
#
library("ggplot2")
#library("sqldf")
source("scripts/shared.R")
# Enable debugging:
options(error = function(){print(head(sys.calls(),-1));print(warnings());q(status=1)}, keep.source=T)

# Command line arguments: input file, output folder
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2)
infile <- args[1] # e.g. "bestroc/WithoutDupl_Norm.all.ev.gz"
outdir = args[2]

d_all=read.csv(gzfile(infile), check.names = TRUE )
# Strip variant postsfixes:
d_all$Name = as.factor(gsub("(_withoutdupl|_norm|_v[0-9]+|_idf)*", "", d_all$Name))
names = unique(d_all["Name"])

# MANUALLY ordered list of data sets, by dimensionality
datasets_5pct <- c("Wilt_05","Glass","Pima_05","Stamps_05","WBC","PageBlocks_05","HeartDisease_05","Hepatitis_05","Lymphography","Annthyroid_05","Cardiotocography_05","Waveform","Parkinson_05","ALOI","WDBC","SpamBase_05","Arrhythmia_05","InternetAds_05")
# Shorter names for the plot
shortnam <- c("Wilt","Glass","Pima","Stamps","WBC", "Page","Heart","Hepat","Lymph","Annth",
              "Cardio","Wave","Park","ALOI","WDBC","Spam","Arrhy","Internet")
stopifnot(length(datasets_5pct) == length(shortnam))
with.legend <- T

for(meas in all.measures) {
  pdf(file=paste0(outdir, "/", meas, ".pdf"), height=6.0, width=9.0)
  #To use legend out of plot
  par(oma = c(3, 1, 1, 1))

  first <- T
  for(i in length(all.algorithms):1) {
    row <- c()
    m <- all.algorithms[i]
    sub_alg = d_all[d_all$Algorithm == m,] # Comma is required, crazy R syntax
    for(d in datasets_5pct) {
      sub_name = sub_alg[sub_alg$Name == d,] # Comma is required, crazy R syntax
      if(nrow(sub_name) > 0) {
          me <- mean(sub_name[[meas]])
      } else {
          cat("No value for", m, d, "\n")
          me <- NA
      }
      row <- c(row, me)
    }

    if(first) {
      yl <- c( ifelse(meas == "ROC.AUC", .5,0.), 1.)
      plot(row, type="o", pch=i-1, lty=2, col=all.colors[i], ylim=yl, axes=FALSE, ann=FALSE)

      axis(1, at=c(1:length(datasets_5pct)), lab=shortnam, cex.axis = 0.6)
      range <- c(0:10)/10 * (yl[2]-yl[1]) + yl[1]
      axis(2, at=range, lab=range, las=1)
      box()
      first <- F
    } else {
      lines(row, type="o", pch=i-1, lty=2, col=all.colors[i])
    }
  }

  title(xlab="Datasets")
  title(ylab=pretty(meas))

  # Build a multi-line horizontal legend, with manually set column widths:
  if (with.legend) {
    legendrows = ceiling(length(all.algorithms)/6)
    j <- 1
    i <- 1
    while(i < length(all.algorithms)) {
      par(fig = c(0, 1, 0, 1), oma = c(legendrows-j, 6, 0, 0), mar = c(0, 0, 0, 0), new = TRUE)
      plot(0, 0, type = "n", bty = "n", xaxt = "n", yaxt = "n")
      k <- min(i + 5, length(all.algorithms.pretty))
      legend("bottomleft",
            legend=all.algorithms.pretty[i:k], col = all.colors[i:k], pch = c((i-1):(k-1)),
            xpd = TRUE, horiz = TRUE, inset = c(0,0), bty = "n",
            cex = 0.8, lty=2, text.width=c(0,0.15,0.185,0.165,0.205,0.2))
      j <- j + 1
      i <- i + 6
    }
  }

  dev.off()
}
