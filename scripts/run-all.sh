#!/bin/bash

# Set the output directory
output_dir="/usr/src/app/output"

# Check if the host's root filesystem is mounted at /hostfs
if [ ! -d /hostfs/var/lib/rpm ]; then
  echo "  ERROR: Host filesystem is not mounted at /hostfs."
  exit 1
fi

# Ensure the output directory exists inside the container (not in the chrooted environment)
if [ ! -d $output_dir ]; then
  mkdir -p $output_dir
fi

echo "- running host-rpms.sh to get all host installed rpms ..."
./host-rpms.sh /dev/stdout container > $output_dir/host-rpms.csv

echo "- comma-separated file stored to $output_dir/host-rpms.csv"

echo "- running scan-rpms.sh to find known CVEs for each rpm ..."
if [ ! -d $output_dir/CVEs ]; then
  mkdir -p $output_dir/CVEs
fi
./scan-rpms.sh container $output_dir/CVEs
echo "- json file(s) stored under $output_dir/CVEs"

echo "- running rpm-deps.sh to get dependencies for all agents ..."
./rpm-deps.sh host \
  hardware-discovery-agent \
  cluster-agent node-agent \
  platform-observability-agent \
  platform-telemetry-agent \
  platform-update-agent > $output_dir/agent-rpms.csv

echo "- comma-separated file stored to $output_dir/agent-rpms.csv"

echo "- running rpm-plot.py to generate the plot for 50 largest rpms ..."
python3 rpm-plot.py $output_dir/host-rpms.csv $output_dir

echo "- plot generated and saved to $output_dir"
