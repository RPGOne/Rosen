#!/usr/bin/python
#
# This script will:
# - Load the results on a single algorithm
# - For each method:
#   - Simulate 1000 random labelings of the same size as the true outliers
#   - Compute the difficulty each
# - Output a new file, one column per method, one simulation per row
#
import gzip, csv, sys, os.path
import numpy
from scipy.stats import rankdata

nam = sys.argv[1]
onam = sys.argv[2]
numsim = 1000

assert(nam.endswith(".raw.gz"))
assert(onam.endswith("-sim.gz"))
inf = gzip.open(nam)
assert(inf.readline()[0] == '#')
r = csv.reader(inf, delimiter=" ")
bylabel = r.next()
assert(bylabel[0] == "bylabel")
outliers = numpy.array(map(float, bylabel[1:]))
outliers = (outliers == 1.)
numdata = len(outliers)
numout = outliers.sum()
assert(numout > 0)
assert(numout < len(outliers))
print "Number of outliers in", os.path.basename(nam),":", numout,"of", numdata

ouf = gzip.open(onam, "w")

maxbin = 10
bins = [float("-inf")] + [x+.5 for x in range(1,10)] + [float("inf")]

allbins = numpy.zeros((0, numdata))
for row in r:
	method = row[0]
	nrow = numpy.array(map(float, row[1:]))
	# Most methods are descending!
	if method.split("-")[0] not in ["FastABOD", "ODIN", "DWOF"]: nrow = -nrow
	# SKIP METHODS NOT IN PAPER!
	if method.split("-")[0] not in ["KNN", "KNNW", "LOF", "SimplifiedLOF", "LoOP", "LDOF", "ODIN", "KDEOS", "COF", "FastABOD", "LDF", "INFLO"]: continue
	nrow = numpy.ceil(rankdata(nrow) / numout)
	nrow[nrow > maxbin] = maxbin
	allbins = numpy.append(allbins, nrow.reshape((1,numdata)), axis=0)

print >>ouf, "Difficulty", "Diversity"
for i in range(numsim):
	sample = numpy.random.choice(range(0, numdata), numout, replace=False)
	dif = numpy.mean(allbins[:,sample].mean(axis=0))
	div = numpy.sqrt(numpy.mean(allbins[:,sample].var(axis=0, ddof=1)))
	print >>ouf, dif, div

