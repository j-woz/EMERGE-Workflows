#!/bin/bash
set -eu

# Build the log2pqt tool

export MAVEN_OPTS="-Dmaven.repo.local=$PWD/.m2/repository"

echo "build.sh: Building with Maven..."
mvn clean package -DskipTests

echo "build.sh: DONE."
# echo "Run with: java -cp target/log-to-parquet-1.0-jar-with-dependencies.jar LogToParquet <input.log> <output.parquet>"
