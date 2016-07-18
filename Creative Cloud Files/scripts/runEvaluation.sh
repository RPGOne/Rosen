#!/bin/bash
set -e # Exit on error
# Parameters:
in=$1
ou=$2

test -z "$in" -o -z "$ou" && ( echo 'Usage: <input> <output>' >&2; exit 1 )
test -e "$in" || ( echo 'Input file does not exist.' >&2; exit 1 )
test -z "$ELKICMD" && ( echo "No ELKICMD specified." >&2; exit 1 )

dou=$(dirname "$ou")
nam=$(basename "$ou" ".ev.gz" )
uou="$dou/$nam.ev"
log="$dou/$nam.log"
lf="tmp/$dou/$nam.lock"

test "$ou" != "$dou/$nam" || ( echo "Expected output name to end in .ev.gz" >&2; exit 1 )

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

# Run the actual job
echo "Generating: $ou" >&2
/usr/bin/time -v $ELKICMD \
de.lmu.ifi.dbs.elki.application.greedyensemble.EvaluatePrecomputedOutlierScores \
-dbc.in $in \
-name "$nam" \
-reversed '(ABOD|ODIN|DWOF)' \
-app.out "$uou" \
>"$log" 2>&1 || exit 1

time=$( grep "User time" "$log" | cut -f2 -d: )
# Compress output
gzip "$uou" "$log"
echo "Completed: $ou in $time seconds." >&2

# To reduce data loss, make successful output readonly:
chmod -w $ou
exit 0
