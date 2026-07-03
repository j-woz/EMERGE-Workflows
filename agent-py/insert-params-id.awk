
# INSERT PARAMS ID AWK
# Inserts a params_id column into the CSV

NR == 1 { print "params_id," $0 }
NR != 1 { print NR - 1   "," $0 }
