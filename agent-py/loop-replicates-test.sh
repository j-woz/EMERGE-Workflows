
# LOOP REPLICATES TEST
# Local test use case

mkdir -pv /tmp/woz/exaepi

cp -uv template.cfg urbanpop_nm.bin NM_Mar16.cases /tmp/woz/exaepi

swift-t -p -n 10 loop-local-replicates.swift template.cfg test-3.csv 2 \
        urbanpop_nm.bin NM_Mar16.cases results.log
