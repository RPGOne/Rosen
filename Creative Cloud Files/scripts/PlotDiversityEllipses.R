#
# Visualize the difficulty of different data sets with ellipses.
# This is probably the prettiest and most interesting plot in the DAMI publication.
#
# This code computes difficulty and diversity as defined in DAMI.
#
# The results agreed with what we got in numpy, too.
#
library("ggplot2")
library("car") # for dataEllipse
# Enable debugging:
options(error =function(){print(sys.calls());print(warnings());q(status=1)}, keep.source=T)
source("scripts/shared.R")

metadata <-read.csv("evaluation/metadata", sep=" ")

indir <- "outbins/*/*/*_withoutdupl_norm*.rocauc.gz"
fnames <- Sys.glob(indir)
cat("Reading", length(fnames), "files.\n")

# Group filenames by their data set:
fnames2 = list()
rates = list()
for (nam in fnames) {
  if (grepl("Lymphography.*catremoved|1ofn", nam)) next; # Include idf only
  if (!grepl("_withoutdupl", nam)) next; # Only without duplicates
  if (!grepl("_norm", nam)) next; # Only normalized
  n1 <- gsub("\\.rocauc\\.gz$", "", basename(nam))
  rate <- as.numeric(metadata[metadata$Name==n1, "Rate"])
  group = gsub("(_withoutdupl|_norm|_v[0-9]+|_idf)*", "", n1)
  if (rate < 0.025 || rate > 0.055) {
    # if (is.null(rates[[group]])) cat(group, rate, " not in 3-5% range.\n")
    rates[[group]] <- T # Warned
    next;
  }
  fnames2[[group]] = c(fnames2[[group]], nam)
}

# Root-mean-square of standard deviations = root-mean of variance
avg_outlier_diversity <- function(x) {return(sqrt(mean(apply(x, 1, var))))}

maxbin = 10

l=list()
for (group in names(fnames2)) {
  cat("Loading group", group, "\n")
  g=list()
  for (nam in fnames2[[group]]) {
    # Careful: first line is usually a comment!
    tmp <- read.csv(gzfile(nam),header=T,blank.lines.skip=T,comment.char="#",sep=" ")
    # Remove the k value from the column name.
    names(tmp) <- gsub("(\\.|-)[0-9]+$", "", names(tmp))
    # Delete methods that we do not include:
    for (n in names(tmp)) {
      if (!(n %in% all.algorithms)) tmp[[n]] <- NULL
    }
    dif <- mean(rowMeans(tmp))
    div <- avg_outlier_diversity(tmp)
    #cat("Difficulty",dif, "Diversity", div, "\n")
    if (grepl("_withoutdupl", nam) && grepl("_norm", nam)) { # Only without duplicates
      g[[nam]] <- c(dif, div)
    }
  }
  if (length(g) > 0) {
    l[[group]] <- g
  } else {
    cat("Ignored all of group", group, "\n")
    print(fnames2[[group]])
  }
}
stopifnot(length(l) > 0)

pdf(file="plot/DiversityEllipses.pdf", width=10, height=7)
par(oma=c(0,0,0,0), mar=c(4,4,1,1), mgp=c(2,1,0), xaxs="i", yaxs="i")
xrange <- c(-.1,10.1)
yrange <- c(-.07,4.07)
seen <- list()
move_labels = -0.15 # 0.04
i <- 1
for (group in names(l)) {
  # Ensure we do not have duplicate labels on the plot:
  prettyname <- gsub("_[0-9]*","", basename(group))
  stopifnot(is.null(seen[[prettyname]]));
  seen[[prettyname]] <- T
  # Convert to div,dif format
  dif <- unlist(l[[group]])
  dif <- array(dif, dim=c(2, length(dif)/2))
  div <- c(dif[2,1:ncol(dif)])
  dif <- c(dif[1,1:ncol(dif)])
  # Draw
  #cat("Drawing:", prettyname, "\n")
  if (length(dif) > 1) {
    dataEllipse(dif,div,xlim=xrange,ylim=yrange,col=all.colorsDark[i],levels=c(0.95),xlab=NA,ylab=NA,center.pch=4,center.cex=2.5,grid=FALSE,axes=F)
  } else {
    plot(dif,div,xlim=xrange,ylim=yrange,col=all.colorsDark[i],cex=2,pch=16,xlab=NA,ylab=NA,axes=F)
  }
  text(mean(dif)-move_labels,mean(div)-move_labels,prettyname,cex=1.0,col=all.colorsDark[i])
  par(new=T)
  i <- i + 1
}

##### Random rankers:
#pout_3pct=c(0.03, 0.03, 0.03, 0.03, 0.03, 0.03, 0.03, 0.03, 0.03, 0.73)
pout_5pct=c(0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.55)
pout=pout_5pct
simulated_size=0.05 * 200 # 5% of 200 = 10 outliers
nummethods=length(all.algorithms) # Used to be "12"
number_random_rankers=100

# simulation of nummethods (12) independent random rankers
indrr_d = c()
indrr_sd = c()
for (i in 1:number_random_rankers) {
  s=sample.int(length(pout), size=simulated_size, replace=TRUE, prob=pout)
  for (j in 2:nummethods) {
    s=cbind(s, sample.int(length(pout), size=simulated_size, replace=TRUE, prob=pout))
  }
  indrr_d = c(indrr_d , mean(s))
  indrr_sd = c(indrr_sd , avg_outlier_diversity(s))
}

# simulation of 12 identical random rankers
iderr_d = c()
iderr_sd = c()
for (i in 1:number_random_rankers) {
  c=sample.int(length(pout), size=simulated_size, replace=TRUE, prob=pout_5pct)
  s=c(c)
  for (j in 2:nummethods) {
    s=cbind(s, c)
  }
  iderr_d = c(iderr_d , mean(s))
  iderr_sd = c(iderr_sd , avg_outlier_diversity(s))
}

move_labels = -.5 # 0.04
#par(new=TRUE)
dataEllipse(indrr_d,indrr_sd,xlim=xrange,ylim=yrange,col=c("black"),levels=c(0.95),xlab=NA,ylab=NA,center.pch=4,center.cex=2.5,grid=FALSE,axes=F)
text(mean(indrr_d)-move_labels,mean(indrr_sd)-move_labels,"RandomRankersIndependent",cex=1.2)
par(new=TRUE)
move_labels = -0.13 # 0.04
dataEllipse(iderr_d,iderr_sd,xlim=xrange,ylim=yrange,col=c("black"),levels=c(0.95),xlab=NA,ylab=NA,center.pch=4,center.cex=2.5,grid=FALSE,axes=F)
text(mean(iderr_d)-move_labels,mean(iderr_sd)-move_labels,"RandomRankersIdentical",cex=1.2)
par(new=TRUE)
## Important: draw with axes only once!
plot(1,0,xlim=xrange,ylim=yrange,col=c("black"),cex=2,pch=16,xlab=NA,ylab=NA,axes=T)
text(mean(1)-move_labels,mean(0)-move_labels,"PerfectResult",cex=1.2)

title(xlab="Difficulty Score", ylab="Diversity Score",cex.lab=1.5)
dev.off()

cat("It is normal to see warnings 'axes is not a graphical parameter'.\nIgnore that, the parameter works nevertheless.\n")
