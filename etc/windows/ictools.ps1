# WAS
$wasInstallDir="C:\IBM\WebSphere\AppServer"
$wasAdmin="wasadmin"
$wasAdminPwd="password"
$wasCellName="icCell"
$wasProfileRoot="C:\IBM\WebSphere\AppServer\profiles"
$wasDmgrProfile="${wasProfileRoot}\dmgr"
$wasDmgrHost="ldap.swg.usma.ibm.com"
$wasDmgrSoapPort=8879

# IHS
$ihsInstallDir="C:\IBM\HTTPServer"

# Connections
$icInstallDir="C:\IBM\Connections"
$icFixesDir="${icInstallDir}\updateInstaller\fixes"

# TDI
$tdiSolutionDir="C:\temp\IBM\TDI\tdisol"

# DB2
$db2InstallDir="C:\Program Files\IBM\sdsV6.3.1db2"
$db2InstanceUser="db2inst1"
$db2ServiceName="DB2DS631-0"

# Other
$separator="================================================================================"
# Some services require a short delay during start/stop operations
$serviceDelaySeconds=5
# Add any apps here for which file differences will not be reported by compareApps.sh.
# This is primarily for Help.ear, which is always different and insignificant.
#excludeCompareApps=(
#    "Help.ear" 
#)