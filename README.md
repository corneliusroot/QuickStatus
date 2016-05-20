# QuickStatus
A shell script to alert to any immediate problems upon login.
It is intended to be installed in /usr/local/bin/quickstatus.sh
Put it in your .bash_profile to get a status every time you log in.

- Check disk status
 - Free Space (OK, Warning, Critical, each in Green, Yellow, Red)
 - Inode Usage (OK, Warning, Critical, each in Green, Yellow, Red)
 - Writeability (checks for Read Only file systems)

- Show Mail queue
 - Can be adapted for Postfix or Exim
 - Configurable threshold for showing a mail queue warning (shows mail queue in red)

- Web Services
 - Checks that port 80 is listening ("Apache OK" in green or "WEB SERVER OFFLINE" in red)
 - If Nginx running on port 80, check for Apache on 8080 (configurable for other services with some easy edits)

- MySQL
 - Checks MySQL listening on port 3306 and reports "MySQL OK" or "MySQL DOWN" in green or red respectively

- Announces system hostname and uptime

Known Issues:
- Logic for port 80 usage could be better, and using 'lsof' to check for services takes a long time on busy systems. 
- File Systems report width gets screwy with the long line lengths used by Logical Volumes. 
