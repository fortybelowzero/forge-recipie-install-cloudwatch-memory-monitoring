#!/bin/bash
#
# Forge Recipie: Install Amazon CloudWatch additional monitoring scripts and
# track memory and disk usage at 5 minute increments.
#
# Amazon AWS Cloudwatch doesnt track memory usage in an EC2 instance, but you
# might want to track it for predicting when to scale.
# AWS provide some (unsupported?) scripts for logging memory and disk usage,
# see here:
# https://aws.amazon.com/code/amazon-cloudwatch-monitoring-scripts-for-linux/
#
# As we're using Laravel Forge for managing a couple of EC2 instances, I wanted
# to be able to install the scripts easily via a Forge Recipie (basically a
# shell script that can be run on the server, so this should work generally
# as a script on Ubuntu linux boxes (and probably other linux boxes too, but
# untested).
#
# Author: Rick Harrison  ( https://github.com/fortybelowzero ; https://twitter.com/sovietuk )
#         for GatenbySanderson.com
# Version: 1.0 [ 22nd December 2017 ]
#
# NOTE: The cloudwatch additional monitoring scripts dont appear to be under
# source control or have a way of easily getting "latest" - the download url
# contains a version number - you'll need to check what the latest version url
# is at:
# https://aws.amazon.com/code/amazon-cloudwatch-monitoring-scripts-for-linux/
# And check it's script usage hasn't changed -- usage instructions for the
# Cloudwatch Monitoring Scripts here:
# http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/mon-scripts.html
# (I'll update this script if i spot it's changed, tho we dont manage many
# forge servers currently, so send me a message/PR if i've not spotted changes
# need making!)
#
# NOTE 2: This script assumes you have the required cloudwatch IAM permissions
#        assigned to the instance - see the above url.
#
# NOTE 3: Run this script as "root" in forge.
#
# The scripts are installed into /opt/gatenbysanderson/aws-scripts-mon/
#
# ================================================================

# Config:

# URL to download the Cloudwatch Monitoring Scripts from.
DOWNLOAD_URL="http://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.1.zip"

# where to install the scripts to on the server:
INSTALL_PATH="/opt/gatenbysanderson"

# do you want the script to install a cronjob itself? Y/N - default is N - you
# probably want to add the cronjob entry yourself in the Forge admin interface,
# if running this via Forge - I suspect otherwise Forge might overwrite the
# crontab.
INSTALL_CRON="N"

# If letting the script install the cron, how often to log the memory usage to
# to cloudwatch in minutes.
FREQUENCY_MINS="5"

echo "-------------------------------------------------------------------------------"
echo "Installing AWS Cloudwatch additonal monitoring scripts and logging memory usage"
echo "-------------------------------------------------------------------------------"

# pre-requisites for running additional cloudwatch monitoring - we need perl
# and perls' libdatetime
echo "Adding required perl packages...."
apt-get update -y
apt-get install -y unzip libwww-perl libdatetime-perl

if [ ! -d "$INSTALL_PATH" ]; then
    mkdir $INSTALL_PATH
fi
cd /opt/gatenbysanderson

ZIPNAME=$(basename $DOWNLOAD_URL)

# check the scripts aren't already installed.
if [ ! -d "$INSTALL_PATH/aws-scripts-mon" ]; then
    echo "Installing Cloudwatch Monitoring Scripts..."
    curl $DOWNLOAD_URL -O
    unzip $ZIPNAME
    rm -f $ZIPNAME
    echo "Scripts installed."
else
    echo "CloudWatch Monitoring Scripts were already installed."
fi

if [ {$INSTALL_CRON,,} == "y" ]; then
  # Add the monitoring scripts to the root crontab.
  echo "Setting up cron-job to run script"

  # Check if the root user already has a crontab, we'll create if not, or
  # append if exists.
  if [ -f "/var/spool/cron/crontabs/root" ]; then
      if grep /var/spool/cron/crontabs/root -Fq "mon-put-instance-data.pl"; then
          echo "Cronjob was already installed, aborting."
          exit 1
      else
          echo "There's already a crontab for root existing, appending ccloudwatch to the existing crontab."
          crontab -l | cat; echo "*/$FREQUENCY_MINS * * * * $INSTALL_PATH/aws-scripts-mon/mon-put-instance-data.pl --mem-used-incl-cache-buff --mem-util --disk-space-util --disk-path=/ --from-cron" | crontab
      fi

  else
      echo "There wasn't a crontab for root on the server, so creating a new one and adding cloudwatch to it."
      echo "*/$FREQUENCY_MINS * * * * $INSTALL_PATH/aws-scripts-mon/mon-put-instance-data.pl --mem-used-incl-cache-buff --mem-util --disk-space-util --disk-path=/ --from-cron" | crontab

  fi
else
  echo "NOTE: Crontab not installed (due to config setting saying not to install it). "
  echo "Set up a scheduled task in Forge Admin to run :\n\n"
  echo "$INSTALL_PATH/aws-scripts-mon/mon-put-instance-data.pl --mem-used-incl-cache-buff --mem-util --disk-space-util --disk-path=/ --from-cron"
  echo "\nevery $FREQUENCY_MINS minutes as root, or add the following to root's crontab:\n\n"
  echo "*/$FREQUENCY_MINS * * * * $INSTALL_PATH/aws-scripts-mon/mon-put-instance-data.pl --mem-used-incl-cache-buff --mem-util --disk-space-util --disk-path=/ --from-cron\n\n"
fi
echo "Done: AWS Cloudwatch Monitoring Scripts Installation."
