# QuickStatus v3.1

A shell script to alert to any immediate problems upon login.
It is intended to be installed in /usr/local/bin/quickstatus.sh
Put it in your .bash_profile to get a status every time you log in.
Use "/usr/local/bin/quickstatus.sh -q" for headless mode
Install as a cron job for basic system monitoring that will send a ntfy.sh push if there are any anomalies.
Run "quickstatus.sh 0 test" (the first argument can by anything, or -q) to test notifications

Quickstatus can be configured to retry on failures with a third argument. Running 

quickstatus -q 0 3

will cause quickstatus to run in headless mode (-q), 0 for production rather than testing, and 3 for three retries. 
If a service is found to be down, it will rerun in 5 seconds with one less retry until either all services are up
or else the retries are exhausted. The exception is CPU load: If there is a CPU alert, it is sent immediately 
without doing any retries.

![This is an image](https://raw.githubusercontent.com/corneliusroot/QuickStatus/master/qsscreenshot.jpg)

- Check disk status
 - Free Space (OK, Warning, Critical, each in Green, Yellow, Red)
 - Inode Usage (OK, Warning, Critical, each in Green, Yellow, Red)
 - Writeability (checks for Read Only file systems)

- Show Mail queue
 - Can be adapted for Postfix or Exim
 - Configurable threshold for showing a mail queue warning (shows mail queue in red)

- Web Services
 - Checks that port 80 is listening ("Apache OK" in green or "WEB SERVER OFFLINE" in red)
 - Configurable for other services with some easy edits

- MySQL/MariaDB
 - Checks MySQL/MariaDB listening on port 3306 and reports "MySQL OK" or "MySQL DOWN" in green or red respectively

- Announces system hostname and uptime

- Integration with ntfy.sh for push notifications to your smart phone
- ntfy pushes are logged in /var/log/messages

Known Issues:
- File Systems report width gets screwy with the long line lengths used by Logical Volumes. 
