# Testing with Test Kitchen

The default **Test Kitchen** configuration uses **Dokken**, which is ideal for
running tests in **GitHub Actions** in a CI environment. However, **Dokken**
is not always sufficent for local testing, especially when a full-fledged
virtual machine is required.

To enable local testing, the **Dokken** configuration has been duplicated into
**.kitchen.vagrant.yml**, allowing you to run tests using **Vagrant** and
VirtualBox on a **Cinc Workstation** setup.

## Setting up for Local Testing

Follow the "Configuring" guide below to configure your system for
Vagrant-based testing. To ensure that Test Kitchen uses the Vagrant
configuration instead of Dokken, set the following environment variable:

```bash
export KITCHEN_YAML=.kitchen.vagrant.yml
```

## Listing Available Test Platforms

To see the available test platforms, run:

```bash
KITCHEN_YAML=.kitchen.vagrant.yml kitchen list
```

Example output:

```bash
$ KITCHEN_YAML=.kitchen.vagrant.yml kitchen list
Instance                 Driver   Provisioner  Verifier  Transport  Last Action    Last Error
default-centos-stream-9  Vagrant  ChefInfra    Inspec    Ssh        <Not Created>  <None>
default-debian-12        Vagrant  ChefInfra    Inspec    Ssh        <Not Created>  <None>
default-ubuntu-2204      Vagrant  ChefInfra    Inspec    Ssh        <Not Created>  <None>
default-ubuntu-2404      Vagrant  ChefInfra    Inspec    Ssh        <Not Created>  <None>
```

## Running a Test on a Specific Platform

To test on a specific platform, use the `kitchen converge` command:

```bash
KITCHEN_YAML=.kitchen.vagrant.yml kitchen converge centos-stream-9
```

Example output:

```bash
 KITCHEN_YAML=.kitchen.vagrant.yml kitchen converge centos-stream-9
-----> Starting Test Kitchen (v3.6.0)
-----> Creating <default-centos-stream-9>...
       Checking for updates to 'bento/centos-stream-9'
       Latest installed version: 202502.21.0
       Version constraints: > 202502.21.0
       Provider: virtualbox
       Architecture: "amd64"
       Box 'bento/centos-stream-9' (v202502.21.0) is running the latest version.
       The following boxes will be kept...
....

       Recipe: fb_init_sample::default
         * fb_helpers_reboot[process deferred reboots] action process_deferred (up to date)
       
       Running handlers:
       Running handlers complete
       Infra Phase complete, 300/585 resources updated in 02 minutes 41 seconds
       [2025-03-09T18:05:51+00:00] WARN: This release of Cinc Client became end of life (EOL) on May 1st 2024. Please update to a supported release to receive new features, bug fixes, and security updates.
       Downloading files from <default-centos-stream-9>
       Finished converging <default-centos-stream-9> (6m24.22s).
-----> Test Kitchen is finished. (7m3.84s)
```

## Limitations and Workarounds

### CentOS Stream 10/RHEL 10 require x86-64-v3 instructions

CentOS Stream 10 and RHEL require x86-64-v3 capabilities to be exposed in
guest VMs. Make sure you are using at least VirtualBox 7.1, as it now
supports x86-64-v3 instructions and that you are running on a supported
host CPU.

If CentOS Stream 10/RHEL10 kernel panics on boot, likely it is due to this
issue. Make sure you're running on at least version 7.1 of VirtualBox and
that your host CPU supports x86-64-v3 instructions.

### Cleaning Up: Stopping and Destroying VMs

Unlike with the Dokken driver, running `kitchen destroy` **without parameters**
will **not** automatically stop and remove running VMs. Instead, you must
specify the instance explicitly.

```bash
KITCHEN_YAML=.kitchen.vagrant.yml kitchen destroy centos-stream-9
````

Example output:

```bash
$ KITCHEN_YAML=.kitchen.vagrant.yml kitchen destroy centos-stream-9
-----> Starting Test Kitchen (v3.6.0)
-----> Destroying <default-centos-stream-9>...
       ==> default: Forcing shutdown of VM...
       ==> default: Destroying VM and associated drives...
       Vagrant instance <default-centos-stream-9> destroyed.
       Finished destroying <default-centos-stream-9> (0m3.74s).
-----> Test Kitchen is finished. (0m4.47s)
```

If a VM is still lingering, you can manually identify and remove it:

1. Find the VM ID:

```bash
vagrant global-status
```

2. Force destroy the VM:

```bash
vagrant destroy -f <VM-ID>
```

### Testing with Different Cinc Client Versions

Similar to the Dokken configuration, if you need to test with a **specific
version** of the Cinc Client (rather than latest), set the `CHEF_VERSION`
environment variable before running Test Kitchen:

```bash
export CHEF_VERSION="18.2.7"
KITCHEN_YAML=.kitchen.vagrant.yml kitchen converge centos-stream-9
```

This will ensure that the specified verison is installed insdie the test VM.


## Configuring an Ubuntu 24.04 Host for Local Testing.

To set up your **Ubuntu 24.04** machine for local testing, ensure you are
running a **64-bit AMD64-compatible host** with **CPU virtualization enabled**
in your system's BIOS.

You'll need to install **VirtualBox, Vagrant, and Cinc Workstation**.

Install [Virtualbox](https://www.virtualbox.org/wiki/Linux_Downloads)

```bash
# Add Oracle VirtualBox's GPG key:
wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc \
  | sudo gpg --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg --dearmor

# Add the repository to Apt sources.list.d
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") contrib" | \
  sudo tee /etc/apt/sources.list.d/virtualbox.list > /dev/null
 
# Install the latest version of Oracle VirtualBox 
sudo apt-get update
sudo apt-get install virtualbox

# Recommended: Reboot to complete configuration
sudo reboot

# Verify that Oracle VirtualBox was installed properly
# Check the version
VBoxManage --version

# Check that the VirtualBox Kernel Modules are loaded properly
# Expected output should include vboxdrv, vboxnetflt and vboxnetadp
$ lsmod | grep vbox
vboxnetadp             28672  0
vboxnetflt             32768  0
vboxdrv               696320  2 vboxnetadp,vboxnetflt
```

Install [Vagrant](https://developer.hashicorp.com/vagrant/downloads#linux):

```bash
# Add HashiCorp's GPG key:
wget -O - https://apt.releases.hashicorp.com/gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add the repository to Apt sources.list.d
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install the latest version of HashiCorp Vagrant
sudo apt update
sudo apt install vagrant

# Verify vagrant is installed properly - check the vagrant version
vagrant --version
```

Install Cinc Workstation 

```bash
# Download and install cinc-workstatus via omnibus installer
curl -L https://omnitruck.cinc.sh/install.sh \
  | sudo bash -s -- -P cinc-workstation -v 25

# Verify cinc-workstation is installed properly
# Check the cinc version
cinc --version

# Initialize [cinc-workstation for your shell](https://docs.chef.io/workstation/getting_started/):
echo 'eval "$(chef shell-init bash)"' >> ~/.bashrc
source ~/.bashrc

# Ensure ruby is pointing at the cinc-workstation ruby
$ which ruby
/opt/cinc-workstation/embedded/bin/ruby
```
