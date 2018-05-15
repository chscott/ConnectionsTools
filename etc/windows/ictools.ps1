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
$tdiSolutionDir="C:\IBM\TDI\tdisol"

# DB2
$db2InstallDir="C:\IBM\DB2"
$db2InstanceUser="db2inst1"
$db2ServiceName="DB2DS631-0"

# Other
$separator="================================================================================"
# Some services require a short delay during start/stop operations
$serviceDelaySeconds=5