# Satellite 6 backup script
This script creates a Satellite backup in offline mode with all the Satellite configurations, certificates and Pulp data. This means that the Satellite services are unavailable during the backup process. This ensures a consistent backup of your data. Please keep this in mind and schedule your Satellite backup at a time where Satellite service unavailability is not a problem. Use this script on your own risk!!! I don't guarantee for any functionalities. Please test this script in a proper test environment first if you are unsure of using this script.

## Installation instructions
Clone this repo on your Satellite server and save the script under /usr/local/bin/ and make it executable:
```
git clone https://github.com/hambuergaer/satellite6_backup.git
cp ./satellite_backup/satellite_backup.sh /usr/local/bin/
chmod 750 /usr/local/bin/satellite_backup
```

## Run the backup script
To execute the backup script you just need to start the script as follows:
```
/usr/local/bin/satellite_backup
```
Depending on the Pulp data the full backup can take some hours.