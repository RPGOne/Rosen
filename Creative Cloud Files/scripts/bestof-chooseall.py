#!/usr/bin/python
#
# Choose the best methods, by *any* of the measures present in the file.
# Measures must start in the column after "k".
#
import gzip, csv, sys
from collections import defaultdict

assert(len(sys.argv)==2)
f = gzip.open(sys.argv[1])
r = csv.reader(f, delimiter=",")
header = r.next()

kcol = header.index("k")

# Remember the original order of algorithms.
order = list()
data = defaultdict(dict)
for row in r:
	key, k = tuple(row[:kcol]), int(row[kcol])
	# Iterate over all measures
	for r in range(kcol+1, len(row)):
		s = float(row[r])
		key2 = header[r]
		if not data.has_key(key): order.append(key)
		c = data[key].get(key2)
		if not c or c[0] < s:
			data[key][key2] = (s, k, row[kcol:])

w = csv.writer(sys.stdout)
w.writerow(header)
# Write in the original order of algorithms.
for key in order:
	# By overwriting the "k" entry, we remove duplicates.
	best = dict()
	for s, k, row in data[key].values():
		best[k] = row
	# Write sorted by k.
	for k, row in sorted(best.items()):
		w.writerow(list(key) + row)
