#!/usr/bin/python
#
# Choose the best methods in a WINDOW around the selected best k.
#
# If a window width of 5 is given, we will select the best k +- 5.
# This will thus yield 11 rows. If k is too large or too small, we still
# try to return 11 rows to make values more comparable.
#
import gzip, csv, sys, glob, re, os, os.path
from os.path import dirname, basename, isdir
from collections import defaultdict

m = sys.argv[1]
f = gzip.open(sys.argv[2])
wwidth = int(sys.argv[3]) # Window width
assert(wwidth > 0)

r = csv.reader(f, delimiter=",")
header = r.next()

kcol = header.index("k")
col = header.index(m)

# Storing (dset, method) -> (best score, best k, min k, max k)
data = dict()
cache = defaultdict(list)
for row in r:
	key, k, s = tuple(row[:kcol]), int(row[kcol]), row[col]
	c = data.get(key)
	if not c:
		data[key] = (s, k, k, k)
	elif c[0] < s:
		data[key] = (s, k, min(k, c[2]), max(k, c[2]))
	else:
		data[key] = (c[0], c[1], min(k, c[2]), max(k, c[2]))
	cache[key].append((k, row))

w = csv.writer(sys.stdout)
w.writerow(header)
for key in sorted(data.keys()):
	s, b, mi, ma = data[key]
	# Adjust minimum and maximum k to have the desired width:
	if mi > b - wwidth:
		ma = min(ma, mi + 2 * wwidth)
	elif ma < b + wwidth:
		mi = max(mi, ma - 2 * wwidth)
	else: # Default case:
		mi = b - wwidth
		ma = b + wwidth
	if ma - mi != 2 * wwidth:
		print >>sys.stderr, "No window of width", (2*wwidth+1), "but only", (ma-mi+1), "for", key
		print >>sys.stderr, data[key][1:], mi, ma
	for k, row in cache[key]:
		if mi <= k and k <= ma:
			w.writerow(row)
