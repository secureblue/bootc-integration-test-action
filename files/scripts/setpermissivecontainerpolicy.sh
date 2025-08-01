#!/usr/bin/env bash

set -oue pipefail

sed -i 's/\breject\b/insecureAcceptAnything/g' /etc/containers/policy.json