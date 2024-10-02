#!/bin/bash

# Usage: ./host-rpms.sh [output_file] [mode]
# mode: "container" (default) to run commands via chroot or "host" to run directly

# Get the output file and mode (defaults to container mode)
output_file=${1:-/dev/stdout}
mode=${2:-"container"}

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

# Write CSV headers
echo "Package Name,Size,Percentage of Total Size" > "$output_file"

# Step 1: Calculate the total size of all installed RPMs in bytes
total_rpm_size=$(run_rpm_command 'rpm -qa --qf "%{SIZE}\n" | paste -sd+ - | bc')

# Step 2: Get a list of all RPMs with their size in bytes, and sort by size
run_rpm_command 'rpm -qa --qf "%{NAME},%{SIZE}\n"' | sort -t',' -k2,2nr | while IFS=',' read -r name size; do
    # Calculate the percentage of total RPM size   taken up by each package
    percentage=$(echo "scale=6; ($size / $total_rpm_size) * 100" | bc)
    # Output the package name, size in bytes, and percentage in CSV format
    echo "$name,$size,$percentage" >> "$output_file"
done
