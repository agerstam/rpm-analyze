# rpm-analyze

## Building Docker Image

Docker runtime must be installed on host operating system. The container image will require a bind mount and running in privileged mode in order to access and enumerate the host's rpm packages. The benefit of running as a container image is that script and Python dependencies are kept within the container and does not add any additional dependencies on the host Tiber OS other than docker being installed.

Build the docker image

```bash
docker build -t rpm-report-generator .
```

## Running the Docker Image

A bind mount for between the container and the host must be created. In this example, the generated output will be saved in `output` directory which should exist before running the container.

```bash
docker run --rm -v /:/hostfs:rw -v $(pwd)/output:/usr/src/app/output --privileged rpm-report-generator
```

The `output` directory will contain three files.

### host-rpms.csv

The `host-rpms.csv` contains all the rpms installed on the image. The file is comma separated and can be imported to Excel. Each rpm line item contains the following information.

| Package name | Package size | % of Total size |
|--------------| -------------| ----------------|

The list is sorted in descending order.

### agent-rpms.csv

The `agent-rpms.csv` contains the size of all baremetal agents and also lists there direct and indirect dependencies on other rpms with sizes. If a rpm package is missing, it is indicated in the size field.

| Package name | Package size | Dependency name | Dependency Size |
|--------------|--------------|-----------------|----------------|

### top_50_rpm_package_sizes.png

This image file contains a bar chart, sorted with the 50 top largest rpm sizes contained within the image with their corresponding names.

![top 50 rpms](/static/top_50_rpm_package_sizes_bar_chart_mb.png)

## Customizing the content

The container image runs `run-all.sh` which is a shell script that invokes the following:

- `host-rpms.sh` which enumerates and creates the CSV for all host rpms
- `rpm-deps.sh` which takes in one or more arguments expressed as rpm package names and generates a combined CSV for all rpms.
- `rpm-plot.py` is a Python script which generates the plot using the CSV data from `host-rpms.sh`
- `scan-rpms.sh` saves all known CVEs for rpms installed on the system by querying [Open Source Vulnerability](https://osv.dev/) APIs.

The scripts can be run natively, outside a container but modification should be done to every execution of `rpm` to not run as chroot.

host-rpms:

```bash
./host-rpms [output=/dev/stdout] [mode=host | container]

./host-rpms /dev/stdout host

Package Name,Size (KB),Percentage of Total Size
libreoffice-core,330092887,4.3700
firefox,233857107,3.0900
glibc-all-langpacks,228747891,3.0300
java-17-openjdk-headless,221441167,2.9300
...
```

rpm-deps:

```bash
./rpm-deps [mode=host | container] [rpm1] [rpm2] ...

./rpm-deps.sh host openssh curl
Package Name,Package Size,Dependency,Dependency Size
openssh,1972540,,
openssh,,audit-libs-3.1.1-1.fc38.aarch64,560921
openssh,,openssh-9.0p1-16.fc38.aarch64,1972540
openssh,,glibc-2.37-4.fc38.aarch64,9985332
openssh,,glibc-2.37-4.fc38.aarch64,9985332
openssh,,openssl-libs-3.0.9-1.fc38.aarch64,7350122

```

scan-rpms:

```bash
./scan-rpms [mode=host | container] <directory>

./scan-rpms.sh host CVEs
No vulnerabilities found for plymouth-graphics
No vulnerabilities found for libiscsi-1.19.0
No vulnerabilities found for usbredir-0.13.0
No vulnerabilities found for woff2-1.0.2
No vulnerabilities found for xkbcomp-1.4.6
Saved response to /usr/src/app/output/CVEs/file-5.44.json
No vulnerabilities found for libsndfile-1.1.0
```

Note! Running natively will not allow for plots to be generated as Python interpreter as well as dependencies. These could be installed if required locally on the host.

```bash
# Install Python dependencies
pip install pandas matplotlib
```

Customization of the Python script can be done easily to generate another view, such as a piechart or show top 30 or top 100 rpm packages by size.
