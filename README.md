# WiFi Scheduler
WiFi scheduler is a application which lets you schedule your router's WiFi on time. It has a console graphical interface, runs on linux x86_64, and can be ran from cron schedules to update every hour.

## Supported routers
- Mercusys AC12G

# Features
- WiFi schedule based on hours, days
- Multiple configuration files for more networks
- Multiple WiFi frequency selector, for routers with more than one band
- Visual console UI

# Cron configuration line
```
0 * * * * /home/user/Documents/wifischedule -f /home/user/Documents/Schedules/schedule.ini -u
```
Replace user with your actual username.
NOTE: You can place the executable wherever you like, and the same is for the schedule file. But make sure the user running the schedule has read access to the schedule!

# Parameters
| Parameter  | Description |
| ------------- | ------------- |
| -f <filepath or --report-file <filepath>  | Specify schedule file name |
| -u or --update  | Update the router the appropriate configuration for the current time |
| -r <count> or --retry <count> | Retry updating the configuration <count> times |
| -s <seconds> or --sleep <seconds> | Sleep <seconds> in-between each retry |
| --about  | Show about dialog |
| --help  | Show the help dialog |

If you do not provide a report file path, the application will choose the default path for you, being `./wificonfig.ini`.

![Screenshot from 2024-01-24 10-01-07](https://github.com/Codrax/Wifi-Scheduler/assets/68193064/f5e3f5d3-b3c4-473d-91bf-fb11d87731b2)
![Screenshot from 2024-01-24 10-01-12](https://github.com/Codrax/Wifi-Scheduler/assets/68193064/48ac000f-22fd-459e-aa00-062766136a91)
