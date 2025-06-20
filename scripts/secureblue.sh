#!/usr/bin/env bash

# Copyright 2025 The Secureblue Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

SERVER_MODE=""
USE_ZFS=""
USE_NVIDIA=""
USE_NVIDIA_OPEN=""
DESKTOP_CHOICE=""
AUTO_YES=""
NON_INTERACTIVE=""

desktop_image_types=(
    "silverblue"
    "kinoite"
    "sericea"
    "cosmic"
)

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Rebases a Fedora Atomic system to a secureblue image.
Can be run interactively or non-interactively via command-line options.

Options:
  --server               Configure for a CoreOS server. Mutually exclusive with --desktop.
  --desktop <type>       Configure for a desktop image. Mutually exclusive with --server.
                         Available types: ${desktop_image_types[*]}
  --zfs                  Enable ZFS support (only with --server).
  --nvidia               Enable NVIDIA proprietary driver support.
  --nvidia-open          Enable NVIDIA open driver support (implies --nvidia).
  --non-interactive      Force non-interactive mode. All unset options default to 'no'.
                         Requires --server or --desktop, and implies --yes.
  -y, --yes              Automatically proceed with the rebase command.
  --help                 Display this help message and exit.

Example (non-interactive):
  $(basename "$0") --non-interactive --desktop kinoite --nvidia
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --help)
        show_help
        ;;
        --server)
        if [[ -n "$DESKTOP_CHOICE" ]]; then echo "Error: --server and --desktop are mutually exclusive." >&2; exit 1; fi
        SERVER_MODE=true
        shift
        ;;
        --zfs)
        USE_ZFS=true
        shift
        ;;
        --nvidia)
        USE_NVIDIA=true
        shift
        ;;
        --nvidia-open)
        USE_NVIDIA_OPEN=true
        shift
        ;;
        --desktop)
        if [[ -n "$SERVER_MODE" ]]; then echo "Error: --server and --desktop are mutually exclusive." >&2; exit 1; fi
        if [[ -z "$2" || "$2" == -* ]]; then echo "Error: --desktop requires an argument." >&2; show_help; fi
        DESKTOP_CHOICE="$2"
        shift
        shift
        ;;
        --non-interactive)
        NON_INTERACTIVE=true
        AUTO_YES=true
        shift
        ;;
        -y|--yes)
        AUTO_YES=true
        shift
        ;;
        *)
        echo "Error: Unknown option: $1" >&2
        show_help
        ;;
    esac
done

if [[ -n "$NON_INTERACTIVE" ]] && [[ -z "$SERVER_MODE" && -z "$DESKTOP_CHOICE" ]]; then
    echo "Error: In non-interactive mode, you must specify either --server or --desktop <type>." >&2
    exit 1
fi

if [[ -n "$USE_ZFS" && -z "$SERVER_MODE" ]]; then
    echo "Error: --zfs can only be used with --server." >&2
    exit 1
fi

if [[ -n "$USE_NVIDIA_OPEN" ]]; then
    USE_NVIDIA=true
fi

if [[ -n "$DESKTOP_CHOICE" ]]; then
    valid_desktop=false
    for type in "${desktop_image_types[@]}"; do
        if [[ "$DESKTOP_CHOICE" == "$type" ]]; then
            valid_desktop=true
            break
        fi
    done
    if ! $valid_desktop; then
        echo "Error: Invalid desktop type '$DESKTOP_CHOICE'." >&2
        echo "Available types: ${desktop_image_types[*]}" >&2
        exit 1
    fi
fi

if ! command -v rpm-ostree &> /dev/null
then
    echo "This script only runs on Fedora Atomic"
    exit 1
fi

version=$(rpm-ostree --version | grep -oP "Version: '\K[^']+" )
year=$(echo "$version" | cut -d '.' -f 1)
subversion=$(echo "$version" | cut -d '.' -f 2)

if [[ "$year" -lt 2024 || ( "$year" -eq 2024 && "$subversion" -lt 9 ) ]]; then
  echo "rpm-ostree is too old, please upgrade before running this script. Found version: $version"
  exit 1
else
  echo "rpm-ostree is 2024.9 or later, proceeding..."
fi

function is_yes {
    case $(echo "$1" | tr '[:upper:]' '[:lower:]') in
        y|yes) return 0;;
        *) return 1;;
    esac
}

image_name=""
additional_params=""

if [[ -z "$SERVER_MODE" && -z "$DESKTOP_CHOICE" ]]; then
    printf "%s\n\n" \
        "Welcome to the secureblue interactive installer!" \
        "After answering the following questions, your system will be rebased to secureblue."
fi

is_server=""

if [[ -n "$SERVER_MODE" ]]; then
    is_server="yes"
elif [[ -n "$DESKTOP_CHOICE" ]]; then
    is_server="no"
else
    read -rp "Is this for a CoreOS server? (yes/No): " is_server
fi

if is_yes "$is_server"; then
    if ! grep VARIANT=\"CoreOS\" /etc/os-release >/dev/null; then
        echo "The current operating system is based on Fedora Atomic."
        echo "Fedora Atomic and CoreOS use different partitioning schemes and are not compatible."
        echo "Refusing to proceed."
        exit 1
    fi
    use_zfs=""
    if [[ -n "$USE_ZFS" ]]; then
        use_zfs="yes"
    elif [[ -n "$NON_INTERACTIVE" ]]; then
        use_zfs="no"
    else
        read -rp "Do you need ZFS support? (yes/No): " use_zfs
    fi
    image_name=$(is_yes "$use_zfs" && echo "securecore-zfs" || echo "securecore")
else
    if grep VARIANT=\"CoreOS\" /etc/os-release >/dev/null; then
        echo "The current operating system is based on CoreOS."
        echo "Fedora Atomic and CoreOS use different partitioning schemes and are not compatible."
        echo "Refusing to proceed."
        exit 1
    fi
    if [[ -n "$DESKTOP_CHOICE" ]]; then
        image_name="$DESKTOP_CHOICE"
    else
        printf "%s\n" \
            "Select a desktop." \
            "Silverblue images are recommended." \
            "Sericea images are recommended for tiling WM users." \
            "Cosmic images are considered experimental."
        PS3=$'Enter your desktop choice: '
        select image_name in "${desktop_image_types[@]}"; do
            if [[ -n "$image_name" ]]; then
                echo "Selected desktop: $image_name"
                break
            else
                echo "Invalid option, please select a valid number."
            fi
        done
    fi
fi

use_nvidia=""

if [[ -n "$USE_NVIDIA" ]]; then
    use_nvidia="yes"
elif [[ -n "$NON_INTERACTIVE" ]]; then
    use_nvidia="no"
else
    read -rp "Do you have Nvidia? (yes/No): " use_nvidia
fi

if is_yes "$use_nvidia"; then
    additional_params+="-nvidia"
    use_open=""
    if [[ -n "$USE_NVIDIA_OPEN" ]]; then
        use_open="yes"
    elif [[ -n "$NON_INTERACTIVE" ]]; then
        use_open="no"
    else
        read -rp "Do you need Nvidia's open drivers? (yes/No): " use_open
    fi
    is_yes "$use_open" && additional_params+="-open"
else
    additional_params+="-main"
fi

image_name+="$additional_params-hardened"

rebase_command="rpm-ostree rebase ostree-unverified-registry:ghcr.io/secureblue/$image_name:latest"

if rpm-ostree status | grep -q '●.*ghcr\.io/secureblue/'; then
    rebase_command="rpm-ostree rebase ostree-image-signed:docker://ghcr.io/secureblue/$image_name:latest"
else
    echo "Note: Automatic rebasing to the equivalent signed image will occur on first run."
fi

printf "Command to execute:\n%s\n\n" "$rebase_command"

rebase_proceed=""

if [[ -n "$AUTO_YES" ]]; then
    rebase_proceed="yes"
else
    read -rp "Proceed? (yes/No): " rebase_proceed
fi

if is_yes "$rebase_proceed"; then
    $rebase_command
fi