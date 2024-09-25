#!/bin/bash

# Usage: ./script.sh mode [rpm1] [rpm2] ... [rpmN]
# mode: "container" to run via chroot or "host" to run directly on the host

# Check for at least two arguments (mode + at least one RPM package)
if [ "$#" -lt 2 ]; then
  echo "Usage: $0 [mode: host | container] [rpm1] [rpm2] ... [rpmN]"
  exit 1
fi

# Get the mode and validate it
mode=$1
shift  # Shift arguments to get the list of RPMs
if [[ "$mode" != "host" && "$mode" != "container" ]]; then
  echo "Error: Invalid mode. Must be 'host' or 'container'."
  exit 1
fi

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

# Function to get the size of a package or 'missing' if not installed
get_package_size() {
  local pkg_name=$1
  run_rpm_command "rpm -q --qf '%{SIZE}\n' \"$pkg_name\"" 2>/dev/null || echo "missing"
}

# Function to get the dependencies of a package (remove duplicates)
get_package_dependencies() {
  local pkg_name=$1
  run_rpm_command "rpm -qR \"$pkg_name\" | awk '{print \$1}' | sort | uniq"
}

# Create a temporary file for raw output
temp_file=$(mktemp)

# Write CSV headers to the temporary file
echo "Package Name,Package Size (KB),Dependency,Dependency Size (KB)" > "$temp_file"

# Process each RPM package passed as an argument
for pkg in "$@"; do
  # Get the package size
  package_size=$(get_package_size "$pkg")

  # Write the package size to CSV (no dependencies yet)
  echo "$pkg,$package_size,," >> "$temp_file"

  # Get the dependencies of the package
  dependencies=$(get_package_dependencies "$pkg")

  # Process each dependency and add to CSV
  for dep in $dependencies; do
    # Get the package that provides the dependency
    dep_pkg=$(run_rpm_command "rpm -q --whatprovides \"$dep\" 2>/dev/null")

    if [ -n "$dep_pkg" ] && [[ ! "$dep_pkg" =~ "no package provides" ]]; then
      dep_size=$(get_package_size "$dep_pkg")
      echo "$pkg,,$dep_pkg,$dep_size" >> "$temp_file"
    else
      echo "$pkg,,$dep,missing" >> "$temp_file"
    fi
  done
done

# Post-process the temporary file to remove duplicates and write to stdout
awk -F, '!seen[$1 FS $3]++' "$temp_file"

# Clean up the temporary file
rm "$temp_file"
