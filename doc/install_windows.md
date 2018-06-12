### System requirements

- Any modern version of Windows

- PowerShell version 5. See [PowerShell configuration](ps_config.md) for more details on PowerShell configuration
  requirements

- Administrator rights

### Dependencies

Certain tools have external executable/library dependencies. These dependencies must be downloaded separately and made 
available on the path for the specified tools to work.

- libxml and related packages are used by the [validateXML](validateXML.md) tool
    - [libxml](ftp://ftp.zlatkovic.com/libxml/64bit/libxml2-2.9.3-win32-x86_64.7z)
    - [iconv](ftp://ftp.zlatkovic.com/libxml/64bit/iconv-1.14-win32-x86_64.7z)
    - [zlib](ftp://ftp.zlatkovic.com/libxml/64bit/zlib-1.2.8-win32-x86_64.7z)
    
- [unzip](http://gnuwin32.sourceforge.net/packages/unzip.htm) is used by the [jarscan](jarscan.md) tool

### Basic installation

1. From your Windows system, download the zip file from [GitHub](https://github.com/chscott/ConnectionsTools/archive/master.zip)
   
2. Unzip the file to a temporary directory.
   
3. Update the file ownership and permissions on the ConnectionsTools-master/etc and ConnectionsTools-master/tools/linux 
   directory files. In this example deployment scenario, we want the files owned by root and a group named icadmins, both of 
   which will have full control. Other users will have no access. Your requirements may vary.
   
4. Copy ConnectionsTools-master\etc\windows\ictools.ps1 to C:\ProgramData\ConnectionsTools\ictools.ps1.
   
5. Copy the ConnectionsTools-master\tools\windows files to a location of your choice. For example, C:\Bin.
   
6. (Optional but recommended) Add the directory you chose in Step 5 to your path. This will let you run the commands without
   needing to specify their full path.
   
7. Modify the contents of C:\ProgramData\ConnectionsTools\ictools.ps1 to match your environment.

You are now ready to use the tools.

### Advanced installation

The advanced installation involves deploying the tools to one node, as documented in the Basic installation section. Instead 
of copying the tools to a regular directory, however, you copy them to a shared folder. Then, on each Connections node, you 
map a drive to the shared folder that contains the tools. This approach makes it much easier to upgrade to new versions of 
ConnectionsTools since you only need to upgrade a single node.