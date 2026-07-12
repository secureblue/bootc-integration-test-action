#!/usr/bin/env bash

# SPDX-FileCopyrightText: (c) 2025-2026 The Secureblue Authors
#
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

echo '{"default":[{"type":"insecureAcceptAnything"}]}' > /etc/containers/policy.json
