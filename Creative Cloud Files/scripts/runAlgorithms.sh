#!/bin/bash
set -e # Exit on error
# Parameters:
in=$1
ou=$2

test -z "$in" -o -z "$ou" && ( echo 'Usage: <input> <output>' >&2; exit 1 )
test -e "$in" || ( echo 'Input file does not exist.' >&2; exit 1 )
test -z "$ELKICMD" && ( echo "No ELKICMD specified." >&2; exit 1 )

dou=$(dirname "$ou")
nam=$(basename "$ou" ".raw.gz" )
uou="$dou/$nam.raw"
log="$dou/$nam.log"
lf="tmp/$dou/$nam.lock"

test "$ou" != "$dou/$nam" || ( echo "Expected output name to end in .raw.gz" >&2; exit 1 )

# Ensure directories exist
test -e "$dou" || mkdir -p "$dou"
test -e "tmp/$dou" || mkdir -p "tmp/$dou"
# Setup lock
# Exit with exit 0 if SOFTFAIL is set for parallelization
if test -e "$lf"; then
	echo "File is currently locked: $lf" >&2
	test "$SOFTFAIL" && exit 0 || exit 1
fi
#echo "Trying to lock: $lf"
lockfile -r0 "$lf" 2>/dev/null || ( echo "File is currently locked: $lf" >&2; test "$SOFTFAIL" && exit 0 || exit 1 )
trap "rm -f $lf" EXIT INT TERM

test -e "$uou" && ( echo "Temporary (uncompressed) output $uou exists. Computation in progress\?" >&2; trap - 0 EXIT INT TERM; exit 1 )

rm "$uou.gz" 2>/dev/null || true
rm "$log.gz" 2>/dev/null || true

SKIP=
# On large data sets, skip methods that would be OOM or take too long
if echo "$nam" | egrep -qi 'ALOI|KDDCup'; then
	SKIP='FastABOD|LDOF|DWOF'
fi

# Run the actual job
/usr/bin/time -v $ELKICMD \
de.lmu.ifi.dbs.elki.application.greedyensemble.ComputeKNNOutlierScores \
-startk 1 -stepk 1 -maxk 100 \
-enableDebug de.lmu.ifi.dbs.elki.application.greedyensemble.ComputeKNNOutlierScores=INFO \
-dbc.in $in \
-dbc.parser ArffParser -arff.externalid '(External-?ID|ID|id)' -arff.classlabel 'Outlier|outlier' \
-outlier.pattern '(outlier|yes)' \
-db.index tree.metrical.covertree.SimplifiedCoverTree \
-covertree.distancefunction minkowski.EuclideanDistanceFunction -covertree.truncate 20 \
-disable "$SKIP" \
-app.out $uou \
>"$log" 2>&1 || exit 1

time=$( grep "User time" "$log" | cut -f2 -d: )
# Compress output
gzip "$uou" "$log"
echo "Completed: $ou in $time seconds." >&2

# To reduce data loss, make successful output readonly:
chmod -w $ou
exit 0
