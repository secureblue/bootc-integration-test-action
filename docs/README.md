# bootc-virtual-machine-action

This repository provides generic GitHub Actions workflows for creating and running KVM virtual machines on GitHub-hosted runners.

Two workflows are available:
*   **Standard VM:** A generic workflow to launch a VM from any provided qcow2 disk image.
*   **CoreOS VM:** A specialized workflow for Fedora CoreOS, including support for Butane/Ignition configuration and post-installation scripting.

## Security Considerations

Workflows use KVM and `libvirt`, the standard Linux virtualization stack. The runner's user is added to groups enabling him or her to interact with the virtualization stack. By default, Ubuntu images include AppArmor, which is specially configured to run in Github-hosted runnners, requiring the adaptation of specific rules to authorize the addition of the ignition file for CoreOS deployments.

SSH keys must be passed via GitHub's encrypted secrets. **We strongly recommend using keys that are specific to this purpose and used nowhere else**.

---

## Workflow: `run-vm-standard`

This workflow provides a generic method for launching a KVM virtual machine from a qcow2 disk image URL. It is suitable for use with any operating system distributed as a cloud image (qcow2). Currently, initialization systems such as cloud-init are not supported.

### Usage

Create a workflow file in your repository (`.github/workflows/main.yml`) and call the generic workflow.

```yaml
name: Deploy Debian VM

on: [push]

jobs:
  launch-vm:
    name: 'Launch Standard Debian VM'
    uses: secureblue/bootc-virtual-machine-action/.github/workflows/run-vm-standard.yml@main
    with:
      vm-name: 'debian-12-test'
      vm-image-url: 'https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2'
      vcpus: 3
      memory-mb: 8192
      disk-size-gb: 10
      startup-wait-seconds: 60
```

Please note the technical specifications of the runners you use. Currently, free Github-hosted Linux runners include 4 vCPUs, 16GB RAM, 14GB SSD under x64 and arm64 for public repositories.

### Inputs

| Input                 | Description                                                                    | Type   | Required | Default       |
| --------------------- | ------------------------------------------------------------------------------ | ------ | -------- | ------------- |
| `runner`              | Runner for the job. Examples: `ubuntu-latest`, `ubuntu-22.04`.                 | string | No       | `ubuntu-latest` |
| `vm-name`             | Name for the virtual machine and its disk in libvirt.                          | string | No       | `vm-standard` |
| `vm-image-url`        | URL to the qcow2 disk image for the VM.                                        | string | Yes      |               |
| `vcpus`               | Number of virtual CPUs for the VM.                                             | number | No       | `3`           |
| `memory-mb`           | Amount of RAM in MB for the VM.                                                | number | No       | `8192`        |
| `disk-size-gb`        | Size (in GB) of the virtual machine disk.                                      | number | No       | `10`          |
| `startup-wait-seconds`| Time in seconds to wait after VM startup before continuing.                    | number | No       | `30`          |
| `additional-packages` | Space-separated list of additional apt packages to install on the runner.      | string | No       |               |

---

## Workflow: `run-vm-coreos`

This is a specialized workflow for launching Fedora CoreOS virtual machines, and systems based on them, such as secureblue. It includes support for Butane/Ignition and executing post-installation commands over SSH.

### Usage

This workflow requires `ssh-public-key` and `ssh-private-key` to be configured as repository secrets. Don't use these keys elsewhere, **they must be dedicated to your Github repository**.

```yaml
# .github/workflows/deploy-coreos-vm.yml
name: Deploy and Configure CoreOS VM

on: [push]

jobs:
  launch-and-configure:
    name: 'Launch and Configure CoreOS VM'
    uses: secureblue/bootc-virtual-machine-action/.github/workflows/run-vm-coreos.yml@main
    with:
      vm-name: 'fcos'
      vcpus: 3
      memory-mb: 8192
      disk-size-gb: 10
      stream: 'stable'
      vm-ip: '192.168.122.3'
      post-install-commands: |
        sudo rpm-ostree upgrade
        sudo systemctl reboot
    secrets:
      ssh-public-key: ${{ secrets.VM_SSH_PUBLIC_KEY }}
      ssh-private-key: ${{ secrets.VM_SSH_PRIVATE_KEY }}
```

`VM_SSH_PUBLIC_KEY` and `VM_SSH_PRIVATE_KEY` must be configured in your repository's `Settings > Secrets and variables > Actions`.

### Inputs

| Input                  | Description                                                                    | Type   | Required | Default         |
| ---------------------- | ------------------------------------------------------------------------------ | ------ | -------- | --------------- |
| `runner`               | Runner for the job. Examples: `ubuntu-latest`, `ubuntu-24.04`.                 | string | No       | `ubuntu-24.04`  |
| `vm-name`              | Name for the virtual machine and its disk in libvirt.                          | string | No       | `vm-coreos`     |
| `vcpus`                | Number of virtual CPUs for the VM.                                             | number | No       | `3`             |
| `memory-mb`            | Amount of RAM in MB for the VM.                                                | number | No       | `8192`          |
| `disk-size-gb`         | Size (in GB) of the virtual machine disk.                                      | number | No       | `10`            |
| `stream`               | Fedora CoreOS stream to use (e.g., `stable`, `testing`).                       | string | No       | `stable`        |
| `butane-version`       | Version of the Butane tool to install on the runner.                           | string | No       | `v0.24.0`       |
| `butane-spec-version`  | Version of the Butane/Ignition spec to use in the config file.                 | string | No       | `1.6.0`         |
| `vm-ip`                | Static IP for the VM on `192.168.122.0/24` network.                            | string | No       | `192.168.122.2` |
| `vm-interface`         | Network interface inside the VM to configure (e.g., `enp1s0`).                 | string | No       | `enp1s0`        |
| `vm-dns-servers`       | Semicolon-separated list of DNS servers for the VM.                            | string | No       | `1.1.1.1;1.0.0.1` |
| `startup-wait-seconds` | Time in seconds to wait after VM startup, before running post-install commands.| number | No       | `180`           |
| `post-install-commands`| Multi-line script of commands to execute on the VM via SSH.                    | string | No       |                 |
| `additional-packages`  | Space-separated list of additional apt packages to install on the runner.      | string | No       |                 |

### Secrets

| Secret              | Description                                                                 | Required |
| ------------------- | --------------------------------------------------------------------------- | -------- |
| `ssh-public-key`    | Public SSH key injected into the `core` user's `authorized_keys` via Ignition.| Yes      |
| `ssh-private-key`   | Private SSH key used by the runner to connect to the VM for post-install commands. | Yes      |

---

## Adding Custom Steps

You can execute your own custom logic after a generic workflow has completed by adding steps within the same job. For example, this allows you to interact with the running virtual machine.
