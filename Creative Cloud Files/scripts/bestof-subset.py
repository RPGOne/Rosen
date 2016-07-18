#!/usr/bin/python
#
# Build a subset of the ORIGINAL scores based on the best performance.
#
# We expect the best methods have previously been selected. We load these, and
# then filter the raw score file retaining only the selected best rows.
#
import gzip, csv, sys, glob, re, os, os.path
from os.path import dirname, basename, isdir
from collections import defaultdict

bestof = sys.argv[1]
rawinput = sys.argv[2]
# Check file names for sanity
assert(bestof.endswith(".ev.gz"))
n = basename(bestof)[:-len(".ev.gz")]
assert(rawinput.endswith(".raw.gz"))
n1 = basename(rawinput)[:-len(".raw.gz")]
assert(n == n1)

_namm = re.compile(r"(.*)-(\d+)")

### Load the best results:
bestk = defaultdict(set)
with gzip.open(bestof) as f:
  r = csv.reader(f)
  header = r.next()
  assert(header[:3] == ["Name", "Algorithm", "k"])

  for row in r:
    assert(row[0] == n)
    # assert(not bestk.get(row[1]))
    bestk[row[1]].add(int(row[2]))

### Load the original data:
inf = gzip.open(rawinput)
ouf = sys.stdout
header = inf.readline()
assert(header[0] == '#')
ouf.write(header)
r = csv.reader(inf, delimiter=" ")
w = csv.writer(ouf, delimiter=" ", lineterminator="\n")
warned = set()

# Read one line at a time, keep only selected
for row in r:
  if row[0] == "bylabel":
    w.writerow(row)
    continue
  m = _namm.match(row[0])
  if not m:
    print >>sys.stderr, "Name did not match", row[0]
    continue
  b = bestk.get(m.group(1), None)
  if not b and not m.group(1) in warned:
    print >>sys.stderr, "Warning: no 'best' k for method", m.group(1)
    warned.add(m.group(1))
    continue
  if int(m.group(2)) in b:
    w.writerow(row)
inf.close()
if ouf != sys.stdout: ouf.close()
