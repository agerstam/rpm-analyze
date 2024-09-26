import pandas as pd
import matplotlib.pyplot as plt
import sys
import os

# Check if the script received the output directory as a command-line argument
if len(sys.argv) < 3:
    print("Usage: python3 rpm-plot-all.py <csv_file> <output_dir>")
    sys.exit(1)

# Get the CSV file and output directory from the command-line arguments
csv_file = sys.argv[1]
output_dir = sys.argv[2]

# Ensure the output directory exists
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

# Load the CSV data into a pandas DataFrame
df = pd.read_csv(csv_file)

# Convert package sizes to numeric (in case there are any text issues)
df["Size"] = pd.to_numeric(df["Size"], errors="coerce")

# Convert the size from bytes to MB
df["Size (MB)"] = df["Size"] / 1024 / 1024

# Sort by package size for better visualization
df = df.sort_values(by="Size (MB)", ascending=False)

# Restrict the plot to only the top 50 largest RPM packages
df_top50 = df.head(50)

# Set up the plot size
plt.figure(figsize=(10, 8))

# Create a horizontal bar chart for the top 50 packages (in MB)
bars = plt.barh(df_top50["Package Name"], df_top50["Size (MB)"], color='skyblue')

# Add labels and title
plt.xlabel("Package Size (MB)")
plt.ylabel("Package Name")
plt.title("Top 50 Largest RPM Packages by Size")

# Write the size (in MB) on each bar
for bar, size in zip(bars, df_top50["Size (MB)"]):
    plt.text(bar.get_width() + 1, bar.get_y() + bar.get_height()/2, f'{size:.2f} MB', va='center')

# Adjust the layout to prevent label cut-off
plt.tight_layout()

# Save the plot to the specified output directory
output_file = os.path.join(output_dir, 'top_50_rpm_package_sizes_bar_chart_mb.png')
plt.savefig(output_file, format='png')

print(f"Plot saved to {output_file}")
