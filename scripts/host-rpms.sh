#!/bin/bash

# Output CSV file: Defaults to STDOUT if not provided as an argument
output_file=${1:-/dev/stdout}

# Get the list of all installed RPM packages with their sizes in KB
# rpm_list=$(rpm -qa --qf "%{NAME},%{SIZE}\n") (Non-containerized)
rpm_list=$(chroot /hostfs /bin/bash -c 'rpm -qa --qf "%{NAME},%{SIZE}\n"')

# Calculate total size of all installed packages, forcing output to be a plain integer
total_size=$(echo "$rpm_list" | awk -F, '{sum += $2} END {printf "%.0f", sum}')

# Ensure total_size is an integer
total_size=${total_size:-0}

# Write CSV headers
echo "Package Name,Size (KB),Percentage of Total Size" > "$output_file"

# Check if total_size is zero or missing and warn the user
if [[ "$total_size" -eq 0 ]]; then
  echo "Warning: Could not determine the total size of all packages. Percentages will be omitted."
  
  # Sort the RPM list by size and write it to the output file without percentage
  echo "$rpm_list" | sort -t, -k2 -n -r | while IFS=, read -r pkg_name pkg_size; do
    # Ensure pkg_size is converted to an integer
    pkg_size=$(echo "$pkg_size" | awk '{printf "%d", $1}')
    # Print package name and size to CSV (without percentage)
    echo "$pkg_name,$pkg_size," >> "$output_file"
  done
else
  # Process each package to calculate its percentage contribution to the total size
  echo "$rpm_list" | sort -t, -k2 -n -r | while IFS=, read -r pkg_name pkg_size; do
    # Ensure the package size is a valid integer
    if [[ -n "$pkg_size" && "$pkg_size" -gt 0 ]]; then
      # Convert pkg_size to an integer to avoid scientific notation issues
      pkg_size=$(echo "$pkg_size" | awk '{printf "%d", $1}')

      # Calculate the percentage of total size using integer math (multiply to avoid float division)
      percentage=$(( pkg_size * 10000 / total_size ))

      # Format the percentage as floating-point with 4 decimal places using printf
      formatted_percentage=$(printf "%.4f" "$(echo "$percentage / 100" | awk '{printf "%.4f", $1/100}')")

      # Print package name, size, and percentage to CSV
      echo "$pkg_name,$pkg_size,$formatted_percentage" >> "$output_file"
    fi
  done
fi
