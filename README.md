# co2info
Code von Office Weather
https://github.com/maddindeiss/co2monitor

# zu finden 
http://luftwache.devbot.de/sensors_client.html


Aufruf darüber gelöst
 ```
/USR/SBIN/CRON
  /bin/sh -c lua /home/pi/co2info/office_weather/report_sensors.lua
    sh -c python /home/pi/co2info/office_weather/monitor_anpassung.py /dev/hidraw0
    ```
