#!/bin/bash

table=
maxnotreturned="1"
validtables="ecatalogue eparties ecollectionevents etaxonomy"
tableflag=false

listcontains() {
	for term in $1; do
	[[ $term = $2 ]] && return 0
	done
	return 1
}

while getopts ":n:t:h" opt; do
	case $opt in
	h) echo "This command will search for duplicate records in the specified"
	   echo "table."
	   echo 
	   echo "That the records are duplicates is based entirely on the"
	   echo "specified columns, it is up to the operator to verify that they"
	   echo "are genuinely duplicate records."
	   echo 
	   echo "-n can be used to specify the maximum number of occurrences which"
	   echo "should not be returned"
	   echo "Default -n is 1, i.e. records which occur one time are not returned"
	   echo "records which occur more than one time are returned."
	   echo "";;
	n) case $OPTARG in
			''|*[!0-9]*) echo "-n must be an integer" >&2;exit 1
		;;
		*) maxnotreturned=$OPTARG 
		;;
	   esac
	   ;;
	t) tableflag=true;
	   if listcontains "$validtables" "$OPTARG"; then
	   tAble=$OPTARG;
	   else echo "invalid table name: $OPTARG. Valid table names are: $validtables" >&2
	   exit 1;
	   fi
	   ;;
	\?) echo "Invalid option: -$OPTARG" >&2;
	   exit 1
	   ;;
	$) echo "Option -$OPTARG requires an argument." >&2;
	   exit 1
	   ;;
 	:) echo "Usage: `basename $0` (-n maxOccurrencesNotReturned (optional, default=1)) -t tableName columnName1 columnName2 ... columnName(x)" >&2;
	   exit 1
	   ;;
	   esac
done

if ! $tableflag
then
	echo "A valid table must be specified using -t. Valid table names are: $validtables" >&2
	exit 1
fi


shift $(( $OPTIND - 1 ))

if [[ $# -eq "0" ]]; then
        echo "Usage: `basename $0` (-n reportRepeatOccurrences>n (optional, default=1)) -t tableName columnName1 columnName2 ... columnName(x)"
        exit 0
fi

i=1
echo "columns searched: $@ ($# columns)"

for word in $@
do
if [ $i -eq $# ]; then
        query+="$word"
else
        query+="$word, "
fi
        i=$[$i+1]
done

texql -R << EOF
select count(record), $query
from
(
        nest
        (
                select $query from $table
        )
        on $query
        forming record
)
where count(record) > $maxnotreturned;
EOF
