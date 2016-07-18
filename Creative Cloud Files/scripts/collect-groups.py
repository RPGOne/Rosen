#!/usr/bin/python
#
# The DAMI analysis processes data in multiple groups:
# * literature vs. semantic
# * all data, less than 20%, less than 10%, less than 5%, 3-5% outliers.
#
# This script builds the appropriate subsets.
#
import sys, gzip, glob, re, os.path

metadata = "evaluation/metadata"
outdir = sys.argv[1]
srcdirs = sys.argv[2:]

# Load metadata, which contains the outlier rates of each data set!
meta = dict()
with open(metadata) as metain:
	line = metain.readline().strip()
	assert(line == "Name Group Semantic Size Dimensionality Outliers Rate"), "Metadata format has changed"
	for line in metain:
		line = line.strip().split(" ")
		meta[line[0]] = (line[0], line[1], line[2], int(line[3]), int(line[4]), int(line[5]), float(line[6]))

# Strip file name postfix:
def shortname(n):
	assert(n.endswith(".ev.gz"))
	return os.path.basename(n[:-len(".ev.gz")])

# Find files, and make sure we have all metadata
names = set()
for s in srcdirs:
	names.update(glob.glob(s+"/*.ev.gz"))
for n in names:
	if not meta.get(shortname(n)):
		print >>sys.stderr, "No metadata for", n
		if os.environ.get("SOFTFAIL"): continue
		sys.exit(1)

# Data sets only that were used in the DMKD publication:
pub = re.compile(r"literature/(ALOI|Glass|Ionosphere|KDDCup99|Lymphography|PenDigits|Shuttle|WBC|WDBC|WPBC|Waveform)|semantic/(Arrhythmia|Cardiotocography|HeartDisease|Hepatitis|Parkinson|SpamBase|Stamps|Wilt)").search
# With Duplicates:
dupl = lambda x: not "_withoutdupl" in x
# Without Duplicates:
nodupl = lambda x: "_withoutdupl" in x
# Normalized:
norm = lambda x: "_norm" in x
# Not normalized:
nonorm = lambda x: not "_norm" in x
# Outlier rate (via metadata!)
leq05 = lambda x: meta[shortname(x)][6] <= 0.05
leq10 = lambda x: meta[shortname(x)][6] <= 0.10
leq20 = lambda x: meta[shortname(x)][6] <= 0.20
threetofive = lambda x: meta[shortname(x)][6] >= 0.03 and meta[shortname(x)][6] <= 0.05
# Semantic vs. literature
semantic = lambda x: "semantic/" in x
literature = lambda x: "literature/" in x

# We build every (filter, variant) combination below.
filters=[
	("Dupl_Norm", lambda x: dupl(x) and norm(x)),
	("Dupl_WithoutNorm", lambda x: dupl(x) and nonorm(x)),
	("WithoutDupl_Norm", lambda x: nodupl(x) and norm(x)),
	("WithoutDupl_WithoutNorm", lambda x: nodupl(x) and nonorm(x)),
]
variants=[
	(".all", lambda x: True),
	(".semantic", semantic),
	(".literature", literature),
	(".leq05", leq05),
	(".leq10", leq10),
	(".leq20", leq20),
	(".03to05", lambda x: threetofive(x) and not "catremoved" in x and not "1ofn" in x),
]

# Open all output files
keys = set()
ofs = dict()
for g, f in filters:
	for v, f in variants:
		ofs[g + v] = gzip.open(outdir+"/"+g+v+".ev.gz", "w")

# Write header, but only once.
wheader = False

# Process one input file at a time
for n in names:
	# Collect output file IDs to write to.
	pos = set()
	for g, f in filters:
		if f(n):
			for v, f2 in variants:
				if f2(n):
					pos.add(g + v)
	# This should not happen in the DAMI scenario:
	if len(pos) == 0:
		print >>sys.stderr, "Skipping data set for aggregation:", n
		continue
	inf = gzip.open(n)
	header = inf.readline()
	# Write header, but only once
	if not wheader:
		for ouf in ofs.values():
			ouf.write(header)
		wheader = header
	assert(header == wheader), "Header mismatch in " + n
	# Write to all matching output files:
	for line in inf:
		for k in pos:
			ofs[k].write(line)

# Close output files
for k, ouf in ofs.items():
	print "Completed:", k
	ouf.close()
