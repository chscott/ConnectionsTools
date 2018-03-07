#!/bin/bash

dmgrProfileDir=/var/IBM/websphere/was/profiles/dmgr
exportCmdVars=${dmgrProfileDir}/bin/setupCmdLine.sh
updateInstallerDir=/opt/IBM/ic/updateInstaller
updateSilent=./updateSilent.sh
icInstallDir=/opt/IBM/ic

# Source setupCmdLine.sh to set WAS_HOME
. ${exportCmdVars}

# Must change to the updateInstall directory or WAS_HOME will be reset
cd ${updateInstallerDir}

# Get installed fixes 
installedFixes=$(${updateSilent} -fix -installDir ${icInstallDir} | grep 'Fix name:' | awk -F ': ' '{print $2}' | sort) 

# Print the fixes
printf "Installed Connections fixes:\n${installedFixes}\n"
