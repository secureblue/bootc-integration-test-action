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

set -oue pipefail


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
