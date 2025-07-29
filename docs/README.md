# bootc-integration-test-action

This repository provides a generic GitHub Action for creating KVM virtual machines and running integration tests against them.

## Security Considerations

Workflows use KVM and `libvirt`, the standard Linux virtualization stack. The runner's user is added to groups enabling him or her to interact with the virtualization stack. By default, Ubuntu images include AppArmor, which is specially configured to run in Github-hosted runnners, requiring the adaptation of specific rules to authorize the addition of the ignition file for CoreOS deployments.

## Usage

```yaml
# .github/workflows/integration-tests.yml
name: secureblue VM integration tests

on: [push]

jobs:
  launch-and-configure:
    name: 'Launch and Configure secureblue VM integration tests'
    uses: secureblue/bootc-virtual-machine-action@main
    with:
      registry: ghcr.io/secureblue
      image: silverblue-main-hardened
      vcpus: 3
      memory-mb: 8192
      tests: |
        ./tests/verify-state.sh
        ./tests/validate-config.sh
```

### Inputs

| Input                  | Description                                                                    | Type   | Required | Default         |
| ---------------------- | ------------------------------------------------------------------------------ | ------ | -------- | --------------- |
| `registry`             | Registry for the image. Example: ghcr.io/secureblue                            | string | Yes      | N/A             |
| `image`                | Image name for the VM. Example: silverblue-main-hardened                       | string | Yes      | N/A             |
| `tests`                | List of test scripts to execute on the VM via SSH after it boots.              | string | Yes      | N/A             |
| `runner`               | Runner for the job. Examples: `ubuntu-latest`, `ubuntu-24.04`.                 | string | No       | `ubuntu-24.04`  |
| `vm-name`              | Name for the virtual machine and its disk in libvirt.                          | string | No       | `vm-coreos`     |
| `vcpus`                | Number of virtual CPUs for the VM.                                             | number | No       | `3`             |
| `memory-mb`            | Amount of RAM in MB for the VM.                                                | number | No       | `8192`          |
| `disk-size-gb`         | Size (in GB) of the virtual machine disk.                                      | number | No       | `10`            |
| `butane-version`       | Version of the Butane tool to install on the runner.                           | string | No       | `v0.24.0`       |
| `butane-spec-version`  | Version of the Butane/Ignition spec to use in the config file.                 | string | No       | `1.6.0`         |
| `vm-ip`                | Static IP for the VM on `192.168.122.0/24` network.                            | string | No       | `192.168.122.2` |
| `vm-interface`         | Network interface inside the VM to configure (e.g., `enp1s0`).                 | string | No       | `enp1s0`        |
| `startup-wait-seconds` | Time in seconds to wait after VM startup, before running post-install commands.| number | No       | `180`           |
