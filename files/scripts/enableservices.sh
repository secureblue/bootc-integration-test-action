#!/usr/bin/env bash

set -oue pipefail

systemctl unmask sshd
systemctl enable sshd

chmod 600 /etc/NetworkManager/system-connections/static.nmconnection
