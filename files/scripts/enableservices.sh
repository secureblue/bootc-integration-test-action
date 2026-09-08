#!/usr/bin/env bash

# SPDX-FileCopyrightText: (c) 2025-2026 The Secureblue Authors
#
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

systemctl unmask sshd.service
systemctl enable sshd.service

systemctl unmask sshd.socket
systemctl enable sshd.socket

# sshd-unix-local.socket only exists at runtime so we can unmask it
# but cannot enable it at build-time.
systemctl unmask sshd-unix-local.socket

systemctl unmask sshd-keygen.target
systemctl enable sshd-keygen.target

chmod 600 /etc/NetworkManager/system-connections/static.nmconnection
