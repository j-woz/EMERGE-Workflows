#!/bin/bash
set -eu

# Build the log2pqt tool

THIS=$( cd "$( dirname "$0" )" && pwd )
cd "$THIS"

export MAVEN_OPTS="-Dmaven.repo.local=$THIS/.m2/repository"

echo "build-log2pqt.sh: Building with Maven..."
mvn clean package -DskipTests

echo "build-log2pqt.sh: DONE."
# echo "Run with: java -cp target/log-to-parquet-1.0-jar-with-dependencies.jar LogToParquet <input.log> <output.parquet>"
