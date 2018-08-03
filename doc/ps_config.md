### PowerShell configuration

- You can get the current version of PowerShell by running the following command:

   ```Shell
   $PSVersionTable.PSVersion.Major
   ```

   If this returns a number less than 5, see <https://www.microsoft.com/en-us/download/details.aspx?id=50395> for details 
   on downloading a Windows update to upgrade the version.
	
- Ensure your assigned policies permit running unsigned scripts. To check, run the following command:

   ```Shell
   Get-ExecutionPolicy -List
   ```
	
	See https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-6 for details on policy options. ConnectionsTools has been tested with the following configuration:
	
   - MachinePolicy: Undefined
   - UserPolicy: Undefined
   - Process: Undefined
   - CurrentUser: Undefined
   - LocalMachine: **Unrestricted**
   
- After downloading the tools, you may need to unblock the files to have them run without a warning. To do this, you can run
  the following commands (assuming the tools were copied to C:\Bin):
  
  ```Shell
  > Get-ChildItem C:\Bin | Unblock-File
  > Get-ChildItem C:\ProgramData\ConnectionsTools | Unblock-File
  ```
   
- If you choose the advanced installation option of hosting the tools on a shared drive, note that Windows may still generate
  a warning message each time you invoke the scripts. This can be disabled by disabling Internet Explorer's Enhanced Security
  Mode.