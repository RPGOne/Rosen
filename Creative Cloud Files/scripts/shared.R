# Shared functionality across plotting scripts

# Fake "hash map" to produce pretty measure names.
pretty.measure=list(
  ROC.AUC="ROC AUC",
  Adjusted.ROC.AUC="Adjusted ROC AUC",
  R.Precision="P@n",
  Adjusted.R.Precision="Adjusted P@n",
  Average.Precision="AP",
  Adjusted.Average.Precision="Adjusted AP",
  Maximum.F1="Maximum F1",
  Adjusted.Maximum.F1="Adjusted Maximum F1"
)
all.measures=c(names(pretty.measure))

# Algorithms to include
pretty.algorithm=list(
  KNN="kNN",
  KNNW="kNNW",
  LOF="LOF",
  SimplifiedLOF="SimplifiedLOF",
  LoOP="LoOP",
  LDOF="LDOF",
  ODIN="ODIN",
  KDEOS="KDEOS",
  COF="COF",
  FastABOD="FastABOD",
  LDF="LDF",
  INFLO="INFLO"
#,DWOF="DWOF"
#,LIC="LIC"
#,VOV="VOV"
#,Intrinsic="ID"
#,IDOS="IDOS"
#,KDLOF="KDLOF"
)
all.algorithms=c(names(pretty.algorithm))

# A list of colors
all.colors=c(
  "blue", "red", "green", "black", "yellow", "gray",
  "darkviolet", "orange", "navy", "pink", "brown", "yellowgreen",
  "darkorange1", "seagreen1", "mediumorchid", "midnightblue", "tomato3", "blueviolet"
)
library(RColorBrewer)
all.colorsNeu=c(
  brewer.pal(n = 9, name = 'Set1'),
  brewer.pal(n = 7, name = 'Set2'),
  rev(brewer.pal(n=12, name='Set3'))
)
all.colorsDark = c("#D92120", "#7FB972", "#E68E34", "#781C81", "#413B93", "#55A1B1", "#D9AD3C", "#E6642C", "#63AD99", "#4065B1", "#B5BD4C", "#488BC2", brewer.pal(n=8, name='Dark2'))

# Prettify method
pretty <- function(s) {
  if (is.list(s)) { return(lapply(s, pretty)); }
  if (is.vector(s) & length(s) > 1) { return(lapply(s, pretty)); }
  r <- pretty.measure[[s]];
  if (is.null(r)) r <- pretty.algorithm[[s]];
  if (is.null(r)) r <- s;
  return(r);
}
all.algorithms.pretty=pretty(all.algorithms)
all.measures.pretty=pretty(all.measures)

# Order methods as desired
order.algorithms=list()
for(i in 1:length(all.algorithms)) order.algorithms[[all.algorithms[i]]] <- i

reorder.algorithms <- function(le) {
  ex <- length(le) + 1
  o <- c()
  for(v in le) {
    if (is.null(order.algorithms[[v]])) {
      o <- c(o, ex); ex <- ex + 1
    } else {
      o <- c(o, order.algorithms[[v]]);
    }
  }
  #o <- sort(as.integer(o))
  return(as.integer(o))
}
