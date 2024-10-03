#!/bin/bash

# Usage: ./scan-rpms.sh [mode] [output_directory]
# mode: "container" (default) to run commands via chroot or "host" to run directly

# Default to container
mode=${1:-"container"}

# Check if the directory is provided as an argument
if [ -z "$2" ]; then
  echo "Usage: $0 <output_directory>"
  exit 1
fi

# Create the output directory if it doesn't exist
output_dir="$2"
mkdir -p "$output_dir"

# Helper function to run rpm commands either via chroot or directly
run_rpm_command() {
  local rpm_command=$1
  if [[ "$mode" == "container" ]]; then
    # Running inside a container, use chroot
    chroot /hostfs /bin/bash -c "$rpm_command"
  else
    # Running directly on the host
    eval "$rpm_command"
  fi
}

# Function to query OSV API for a package and version
query_osv() {
    package_name=$1
    package_version=$2
    output_dir=$3

    response=$(curl -s "https://api.osv.dev/v1/query" -d '{
      "package": {
        "name": "'$package_name'"
      },
      "version": "'$package_version'"
    }')

    # Check if the response is non-empty (contains vulnerabilities)
    if [[ "$response" != "{}" ]]; then
        # Save the response to a file in the specified directory
        output_file="$output_dir/${package_name}-${package_version}.json"
        echo "$response" | jq > "$output_file"
        echo "Saved response to $output_file"
    else
        echo "No vulnerabilities found for $package_name-$package_version"
    fi
}

export -f query_osv  # Export function so it's available to xargs

# Get the list of packages, limit to 350 or fewer, and process them in parallel
run_rpm_command 'rpm -qa --qf "%{NAME}-%{VERSION}\n"' | head -n 350 | \
  while read package; do
    package_name=$(echo "$package" | cut -d- -f1)
    package_version=$(echo "$package" | cut -d- -f2)
    echo "$package_name $package_version $output_dir"
  done | xargs -n 3 -P 10 bash -c 'query_osv "$@"' _

