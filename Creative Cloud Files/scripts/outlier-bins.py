#!/usr/bin/python
#
# Compute the outlier bins analysis used in DAMI.
#
# This data is used to generate the "heatmap" visualizations
#
# 1. Map each outlier to its rank.
# 2. bin = ceil(rank / numoutlier)
# 3. Count how often each bin occurs.
#
import gzip, csv, sys
import numpy
from scipy.stats import rankdata

nam = sys.argv[1]
assert(nam.endswith(".raw.gz"))
onam = sys.argv[2]
assert(onam.endswith(".gz"))

# Load the input data.
inf = gzip.open(nam)
# Read the comment line:
assert(inf.readline()[0] == '#')
r = csv.reader(inf, delimiter=" ")
# Read the bylabel result, to infer the number of outliers
bylabel = r.next()
assert(bylabel[0] == "bylabel")
outliers = numpy.array(map(float, bylabel[1:]))
outliers = (outliers == 1.)
numout = outliers.sum()
assert(numout > 0)
assert(numout < len(outliers))
# print "Number of outliers in", nam,":", numout

ouf = gzip.open(onam, "w")

# Binning that we use:
maxbin = 10
bins = [float("-inf")] + [x+.5 for x in range(1,10)] + [float("inf")]

mnames = []
outbins = numpy.zeros((0,numout), numpy.int8)
for row in r:
	method = row[0]
	nrow = numpy.array(map(float, row[1:]))
	# Most methods are descending!
	if method.split("-")[0] not in ["FastABOD", "ODIN", "DWOF"]: nrow = -nrow
	nrow = numpy.ceil(rankdata(nrow) / numout)
	nrow[nrow > maxbin] = maxbin
	mnames.append(method)
	nrow = numpy.array(nrow, numpy.int8)
	outbins = numpy.append(outbins, nrow[outliers].reshape((1,numout)), axis=0)
# Compute difficulty and diversity to compare to R.
div = numpy.sqrt(outbins.var(axis=0, ddof=1).mean())
print nam
print >>ouf, "# Difficulty", numpy.mean(outbins), "Diversity", div
print >>ouf, " ".join(mnames)

# Output data for visualization in R-
outbins = outbins.T
# Sort by mean
means = outbins.mean(axis=1)
assert(len(means) == outbins.shape[0])
order = numpy.argsort(means)
outbins = outbins[order,:]
assert(len(means) == outbins.shape[0])
for row in outbins:
  print >>ouf, " ".join(map(str, row))

