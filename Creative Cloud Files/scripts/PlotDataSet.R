#
# Plot the performance curve of each algorithm, for each k on this data set.
# This will produce one output file per measure.
#
library("ggplot2")
suppressMessages(library("dplyr"))
source("scripts/shared.R")
# Enable debugging:
options(error = function(){print(head(sys.calls(),-1));print(warnings());q(status=1)}, keep.source=T)

# Command line: 1. Input 2. Output folder
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2)
infile <- args[1];
outdir <- args[2]

with.title <- T
with.legend <- T

d_all=read.csv(gzfile(infile), check.names = TRUE)
stopifnot(length(levels(d_all$Name))==1)
# Double-check with header column:
stopifnot(names(d_all)[1:3] == c("Name", "Algorithm", "k"))
measures=names(d_all)[4:length(names(d_all))]
##################

for(level in levels(d_all$Algorithm)) {
  if (!(level %in% all.algorithms)) {
    cat("Droping unknown method from the data:", level, "\n");
    d_all = filter(d_all, Algorithm != level);
  }
}
d_all = data.frame(d_all)

dataset <- d_all$Name[1] # There is only one name
for (measure in measures) {
  cat("Generating:", dataset, "measure:", measure, "\n");
  data <- list()
  d_all %>% group_by(Algorithm) %>% do({
    alg <- as.character(.[["Algorithm"]][1]) # Convert from factor
    ks = .[["k"]]
    ms = .[[measure]]
    line = c()
    for(i in 1:nrow(.)) { line[ks[i]] = ms[i]; }
    data[[alg]] <<- line # Modify outside!
    return(data.frame()); # Return empty.
  });
  #cat("Have",length(data),"algorithms.\n")

  # Plotting ranges:
  mini = min(sapply(data, function(x) min(x, na.rm=TRUE)))
  maxi = max(sapply(data, function(x) max(x, na.rm=TRUE)))
  mini = floor(mini * 20) / 20
  maxi = ceiling(maxi * 20) / 20
  g_range <- range(mini,maxi)
  x_range <- range(0, max(sapply(data, length)) + 1)

  dirname = paste0(outdir, "/")
  if (!dir.exists(dirname)) { dir.create(dirname, recursive = T) }
  fname <- paste0(dirname,dataset, "-",measure,".pdf")
  # cat("Generating",fname,"\n")
  pdf(file=fname, height=5.0, width=8.0)
  # Compute space for legend outside of plot:
  if (with.legend) {
    legendrows = ceiling(length(all.algorithms)/6)
    par(oma = c(legendrows, 0, 0, 0), mar=c(4,4,1.5,.75)+.1, xaxs="i", yaxs="i", mgp=c(2.5,.5,0))
  } else {
    par(oma = c(0, 0, 0, 0), mar=c(3.5,4,1.5,.75)+.1, xaxs="i", yaxs="i", mgp=c(2.5,.5,0))
  }

  # Plot in reverse order (so most important is on top)
  first <- T
  for(m in length(all.algorithms):1) {
    seq <- data[[all.algorithms[m]]]
    if (is.null(seq)) {
      cat("Algorithm missing:", all.algorithms[[m]], "for", dataset,"(may be okay?)\n")
      next
    }
    if (first) {
      plot(1:length(seq), seq, type="o", pch=m-1, lty=2, col=all.colors[m], xlim=x_range, ylim=g_range, axes=FALSE, ann=FALSE)

      # Axis labels
      range <- c(1,10,20,30,40,50,60,70,80,90,100)
      axis(1, at=range, lab=range)
      axis(2, las=1)

      # Create box around plot
      box()
      first <- F
    } else {
      lines(1:length(seq), seq, type="o", pch=m-1, lty=2, col=all.colors[m])
    }
  }

  if (with.title) {
    title(main=dataset, font.main=4)
  }
  title(xlab="Neighborhood size")
  title(ylab=pretty(measure))

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
