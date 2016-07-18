#!/usr/bin/python
#
# Choose the best k for each method by ONE measure only (e.g. ROC AUC).
#
import gzip, csv, sys
from collections import defaultdict

assert(len(sys.argv)==3)
m = sys.argv[1]
f = gzip.open(sys.argv[2])
r = csv.reader(f, delimiter=",")
header = r.next()

kcol = header.index("k")
col = header.index(m)

data = dict()
for row in r:
	key, k, s = tuple(row[:kcol]), row[kcol], float(row[col])
	c = data.get(key)
	if not c or c[0] < s:
		data[key] = (s, row[kcol:])

w = csv.writer(sys.stdout)
w.writerow(header)
for key in sorted(data.keys()):
	w.writerow(list(key) + data[key][1])
