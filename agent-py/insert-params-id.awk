
# INSERT PARAMS ID AWK
# See insert-params-id.sh

NR == 1 { print "params_id," $0 }
NR != 1 { print NR - 1   "," $0 }
