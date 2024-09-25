#!/bin/bash

# Function to get the size of a package or 'missing' if not installed
get_package_size() {
  local pkg_name=$1
  # rpm -q --qf '%{SIZE}\n' \"$pkg_name\"" 2>/dev/null || echo "missing" (Non containerized)
  chroot /hostfs /bin/bash -c "rpm -q --qf '%{SIZE}\n' \"$pkg_name\"" 2>/dev/null || echo "missing"
}

# Function to get the dependencies of a package (remove duplicates)
get_package_dependencies() {
  local pkg_name=$1
  # rpm -qR "$pkg_name" | awk '{print $1}' | sort | uniq (Non containerized)
  chroot /hostfs /bin/bash -c "rpm -qR \"$pkg_name\" | awk '{print \$1}' | sort | uniq"
}

# Check if at least one RPM package argument is provided
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 [rpm1] [rpm2] ... [rpmN] > output.csv"
  exit 1
fi

# Write CSV headers
echo "Package Name,Package Size (KB),Dependency,Dependency Size (KB)"

# Process each RPM package passed as an argument
for pkg in "$@"; do
  # Get the package size
  package_size=$(get_package_size "$pkg")

  # Write the package size to CSV (no dependencies yet)
  echo "$pkg,$package_size,,"

  # Get the dependencies of the package
  dependencies=$(get_package_dependencies "$pkg")

  # Process each dependency and add to CSV
  for dep in $dependencies; do
    # dep_pkg=$(rpm -q --whatprovides "$dep" 2>/dev/null) (Non containerized)
    dep_pkg=$(chroot /hostfs /bin/bash -c 'rpm -q --whatprovides "$dep" 2>/dev/null')

    if [ -n "$dep_pkg" ] && [[ ! "$dep_pkg" =~ "no package provides" ]]; then
      dep_size=$(get_package_size "$dep_pkg")
      echo "$pkg,,$dep_pkg,$dep_size"
    else
      echo "$pkg,,$dep,missing"
    fi
  done
done
