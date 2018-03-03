# getAppLogs

getAppLogs is a user-friendly front end for the WebSphere Application Server logViewer command.

## Installation

1. Copy getAppLogs.sh to your WAS profile's bin directory.

2. Ensure proper ownership and permissions:

   ```Bash
   $ sudo chown root.root getAppLogs.sh
   $ sudo chmod 755 getAppLogs.sh
   ```
   
Note that you can place the script in another location and create a symlink in your profile's bin directory. This approach allows you to have a single copy of the script shared among multiple profiles.

## Usage
getAppLogs.sh [application] [time]

- **application** is any valid WebSphere application name or the special value 'All'
- **time** is an integer representing minutes of logging to retrieve or the special values 'today' or 'lastHour'

Logs are created in the profile's logs directory. Note that they are not created in the application server subdirectory of the logs directory and are instead created directly in the logs directory. Logs have the same name as the application provided.

As an example, suppose you have a profile /var/IBM/WebSphere/AppServer/profiles/connections and have copied getAppLogs.sh to /var/IBM/WebSphere/AppServer/profiles/connections/bin. You run getAppLogs.sh News to collect all logs for the News application. You will then have a News.log file in /var/IBM/WebSphere/AppServer/profiles/connections/logs.
    
## Examples

- Get all messages from all applications:
  
  ```Bash
  getAppLogs.sh All
  ```
  
- Get all messages from the Activities application:

  ```Bash
  getAppLogs.sh Activities
  ```
  
- Get all messages since midnight (today) from all applications:

  ```Bash
  getAppLogs.sh All today
  ```
  
- Get all messages since midnight (today) from the Blogs application:

  ```Bash
  getAppLogs.sh Blogs today
  ```
  
- Get all messages in the last hour from all applications:

  ```Bash
  getAppLogs.sh All lastHour
  ```
  
- Get all messages in the last hour from the Communities application:

  ```Bash
  getAppLogs.sh Communities lastHour
  ```
  
- Get all messages in the last 5 minutes from all applications:

  ```Bash
  getAppLogs.sh All 5
  ```
  
- Get all messages in the last 5 minutes from the Dogear application:

  ```Bash
  getAppLogs.sh Dogear 5
  ```