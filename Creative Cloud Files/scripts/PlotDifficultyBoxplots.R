#
# Plot the "difficulty boxplots" for each method.
#
# We only include a certain subset of the data below.
# Much of the heavy work was done by python/numpy before,
# R turned out to have trouble even reading the input data because of the number of columns.
#
library("ggplot2")
# Enable better debugging:
options(error=function(){print(sys.calls());print(warnings());q(status=1)}, keep.source=T)
source("scripts/shared.R")

metadata <-read.csv("evaluation/metadata", sep=" ")

indir <- "outbins/*/*/*_withoutdupl_norm*.rocauc.gz"
fnames <- Sys.glob(indir)
cat("Reading", length(fnames), "files.\n")

filter <- T # Only include 3-5%
numsim <- 100

# Group filenames by their data set:
fnames2 <- list()
rates <- list()
for (nam in fnames) {
  if (grepl("_catremoved|_1ofn", nam)) next; # Include idf only
  if (!grepl("_withoutdupl", nam)) next; # Only without duplicates
  if (!grepl("_norm", nam)) next; # Only normalized
  n1 <- gsub("\\.rocauc\\.gz$", "", basename(nam))
  rate <- as.numeric(metadata[metadata$Name==n1, "Rate"])
  group <- gsub("(_withoutdupl|_norm|_v[0-9]+|_idf)*", "", n1)
  # Filter out data with less than 3 or more than 5%
  # In particular (IMPORTANT) this prevents 2% and 5% versions to merge.
  if (filter && (rate < 0.025 || rate > 0.055)) {
    # if (is.null(rates[[group]])) cat(group, rate, " not in 3-5% range.\n")
    rates[[group]] <- T # Warned
    next;
  }
  fnames2[[group]] <- c(fnames2[[group]], nam)
}

maxbin = 10

difficulties <- list()
simulations <- list()
for (group in sort(names(fnames2))) {
  cat("Loading group", group, "\n")
  g <- c()
  s <- c()
  for (nam in fnames2[[group]]) {
    # Careful: first line is usually a comment!
    tmp <- read.csv(gzfile(nam),header=T,blank.lines.skip=T,comment.char="#",sep=" ")
    # Remove the k value from the column name.
    names(tmp) <- gsub("(\\.|-)[0-9]+$", "", names(tmp))
    # Delete methods that we do not include:
    for (n in names(tmp)) if (!(n %in% all.algorithms)) tmp[[n]] <- NULL
    g <- c(g, mean(rowMeans(tmp)))

    # Read random simulations, too
    simnam <- gsub("\\.rocauc\\.gz$", ".rocauc-sim.gz", nam)
    stopifnot(simnam != nam)
    tmp2 <- read.csv(gzfile(simnam),header=T,sep=" ")
    s <- c(s, mean(tmp2$Difficulty))
  }
  if (length(g) == 0) {
    cat("WARNING: Ignored all of group", group, "\n")
    print(fnames2[[group]])
    next
  }
  if (filter) group <- gsub("_[0-9]+$", "", group)
  difficulties[[group]] <- g
  simulations[[group]] <- s
}
stopifnot(length(difficulties) > 0)
print(summary(difficulties))
print(summary(simulations))

pdf(file="plot/DifficultyBoxplots.pdf", width=12, height=8)
par(mar=c(5,15,1,1))
boxplot(difficulties,las=1,horizontal=T,ylim=c(1,10),col=(c("lightblue")),cex.axis=1.5)
par(new=T)
boxplot(simulations,las=1,horizontal=T,ylim=c(1,10),col=(c("red")),cex.axis=1.5)
title(xlab="Difficulty Score",cex.lab=1.5)
dev.off()
