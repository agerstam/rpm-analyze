# Use a smaller Python image as the base
FROM python:3.9-slim

# Install necessary packages (rpm, bash, gnupg2, dirmngr)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    rpm \
    bash \
    gnupg2 \
    dirmngr \
    bc \ 
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install pandas matplotlib

# Set the working directory
WORKDIR /usr/src/app

# Copy scripts into the container
COPY scripts/host-rpms.sh /usr/src/app/host-rpms.sh
COPY scripts/rpm-deps.sh /usr/src/app/rpm-deps.sh
COPY scripts/rpm-plot.py /usr/src/app/rpm-plot.py
COPY scripts/run-all.sh /usr/src/app/run-all.sh
COPY scripts/scan-rpms.sh /usr/src/app/scan-rpms.sh

# Ensure scripts are executable
RUN chmod +x /usr/src/app/*.sh

# Create an output directory
RUN mkdir -p /usr/src/app/output

# Default entry point to run the scripts
CMD ["/usr/src/app/run-all.sh"]
