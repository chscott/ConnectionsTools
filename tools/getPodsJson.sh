#!/bin/bash

scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. "${scriptDir}/utils.sh"

${kubectl} get pods --namespace ${icNamespace} --output json
