#!/bin/bash

# Set the output directory
OUTPUT_DIR="/usr/src/app/output"

# Check if the host's root filesystem is mounted at /hostfs
if [ ! -d /hostfs/var/lib/rpm ]; then
  echo "Error: Host filesystem is not mounted at /hostfs."
  exit 1
fi

# Ensure the output directory exists inside the container (not in the chrooted environment)
if [ ! -d $OUTPUT_DIR ]; then
  mkdir -p $OUTPUT_DIR
fi

echo "Running host-rpms.sh to generate CSV for all host rpms..."
./host-rpms.sh /dev/stdout container > $OUTPUT_DIR/host-rpms.csv

echo "CSV for all RPMs saved to $OUTPUT_DIR/host-rpms.csv"

echo "Running rpm-deps.sh [container | host] [rpm1] [rpm2] ... [rpm(n)] to generate CSV for key rpm packages..."
./rpm-deps.sh container curl openssh > $OUTPUT_DIR/agent-rpms.csv
echo "CSV for key rpm packages saved to $OUTPUT_DIR/agent-rpms.csv"

echo "Running rpm-plot.py to generate the plot..."
python3 rpm-plot.py $OUTPUT_DIR/host-rpms.csv $OUTPUT_DIR

echo "Plot generated and saved to $OUTPUT_DIR"
