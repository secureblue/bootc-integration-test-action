# bootc-integration-test-action

This action runs integration tests against any bootable container image.

## How it works

1. The image to be tested and the tests to be run are passed in via the action inputs.
2. [BlueBuild](https://blue-build.org/) is used to add a thin layer onto the image to ensure SSH, networking, and container policies are configured to allow testing to function. This test image is pushed to the registry using an `integrationtest-UUID` tag.
3. [bootc-image-builder](https://github.com/osbuild/bootc-image-builder) is used to generate a qcow image with preconfigured SSH.
4. The resulting qcow image is imported into [virt-install](https://linux.die.net/man/1/virt-install).
5. Once the machine has booted, tests are executed on the VM and their output is recorded.
6. As a cleanup step, the test image is removed from the registry.
7. Test output logs are uploaded to GitHub Artifacts and the action passes if all tests exited with exit code 0.

## Usage

```yaml
# .github/workflows/integration-tests.yml
name: integration-tests
permissions: {}
on:
  schedule:
    - cron: "00 7 * * *" # run at 7:00 UTC every day
jobs:
  integration-tests:
    name: Run integration tests
    runs-on: ubuntu-24.04
    permissions:
      contents: read
      packages: write
      id-token: write
    strategy:
      fail-fast: false
    steps:
      - name: Checkout repo
        uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
        with:
          persist-credentials: false
      - name: Run integration tests
        uses: secureblue/bootc-integration-test-action@05aa93d5e9d1e128c8d0772fd534fed5c73f9271 # v0.0.3
        with:
          registry: ghcr.io/secureblue
          image: silverblue-main-hardened
          token: ${{ secrets.GITHUB_TOKEN }}
          tests: |
            ./.github/workflows/integration_tests/test1.sh
            ./.github/workflows/integration_tests/test2.sh
            ./.github/workflows/integration_tests/test3.sh
            ./.github/workflows/integration_tests/test4.sh
```

### Inputs

| Input                  | Description                                                                    | Type   | Required | Default         |
| ---------------------- | ------------------------------------------------------------------------------ | ------ | -------- | --------------- |
| `registry`             | Registry for the image. Example: ghcr.io/secureblue                            | string | Yes      | N/A             |
| `image`                | Image name for the VM. Example: silverblue-main-hardened                       | string | Yes      | N/A             |
| `tests`                | List of test scripts to execute on the VM via SSH after it boots.              | string | Yes      | N/A             |
| `token`                | GitHub token                                                                   | string | Yes      | N/A             |
| `data-files`           | List of data files to be copied to the VM via SSH after it boots.              | string | No       | (empty)         |
| `vm-name`              | Name for the virtual machine and its disk in libvirt.                          | string | No       | `vm-bootc`      |
| `vcpus`                | Number of virtual CPUs for the VM.                                             | number | No       | `3`             |
| `memory-mb`            | Amount of RAM in MB for the VM.                                                | number | No       | `8192`          |
| `disk-size-gb`         | Size (in GB) of the virtual machine disk.                                      | number | No       | `20`            |
| `startup-wait-seconds` | Time in seconds to wait after VM startup, before running post-install commands.| number | No       | `180`           |
