# "Recipie" (bash script) for Laravel Forge to install Amazon AWS CloudWatch memory and disk usage

Cron-able Bash Script to install Amazon AWS Cloudwatch additional linux monitoring scripts, and optionally to configure
Cron to track memory/diskusage every 5 minutes and send to CloudWatch.

I created this to better track if we were nearing the memory limits of a server that we're going to host multiple (and a growing number of) low-traffic CMS driven websites, this allows us to start with a medium EC2 instance, and hopefully better
predict when to scale it up to a more powerful server by tracking memory (and cpu) usage.

You can just run this script under Ubuntu - its a vanilla bash script for Ubuntu (which is what Laravel Forge provisions)

## Pre-requistes

Cron && Curl.

The script will install Perl and Zip packages if not already installed.

## Installation

Amend the configuration options at the top of the script. Pay careful note to the fact this script doesnt install the 
Crontab entry to make it track usage every X minutes unless you switch that on in the config (if using Forge you probably want
to leave that off and add a scheduled task to run this command instead (as root):

```
$INSTALL_PATH/aws-scripts-mon/mon-put-instance-data.pl --mem-used-incl-cache-buff --mem-util --disk-space-util --disk-path=/ --from-cron
```
Once installed and running via Cron, you should see memory and disk usage stats appearing in CloudWatch monitoring for the server.

## Disclaimer

My bash-fu is a little rusty - if there's a better way of writing/improving bits of it please let me know :-)
Use this script at your own risk. I've had no problems with it, but I can't guarantee it will never fail.

## Credits
Written by Rick Harrison : https://www.fortybelowzero.com ( @sovietuk on twitter )
