#!/usr/bin/lua

--[[           Moduleinbindung            ]]--
-- Selbstredend... Hoffe ich....            --
----------------------------------------------
status, socket = pcall(require, "socket")
if not status then
  print("Bitte Socket Erweiterung installieren.")
  print("sudo apt-get install lua-socket")
  os.exit(1)
end
----------------------------------------------


--[[        Konfigurationsbereich         ]]--
-- Selbstredend... Hoffe ich....            --
----------------------------------------------
rcon_port   = 9910
rcon_host   = "luftwache.devbot.de" -- !DONT TOUCH!
rcon_user   = "new"                -- EIGENEN USER BEANTRAGEN!
rcon_secret = "xxxxxxx"                 -- UND PASSENDES SECRET!
----------------------------------------------


--[[           Helferfunktionen           ]]--
-- einfach ignorieren.... Hier geht es um   --
-- ganz andere Dinge ;-)                    --
----------------------------------------------
function os.capture(cmd, raw)
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  if raw then return s end
  s = string.gsub(s, '^%s+', '')
  s = string.gsub(s, '%s+$', '')
  s = string.gsub(s, '[\n\r]+', ' ')
  return s
end
----------------------------------------------


--[[           Datenbeschaffung           ]]--
-- Da wir hier einen RaspberryPI nutzen,    --
-- bietet sich der CPU/GPU Temp Sensor an.  --
----------------------------------------------
raspberry_temp    = os.capture('vcgencmd measure_temp | grep -o "[0-9\.]*"')
usb_sensor        = os.capture('python /home/pi/co2info/office_weather/monitor_anpassung.py /dev/hidraw0')

-- Der inhalt von usb_sensor sieht ca. so aus CO2:  761 T: 22.48
print(usb_sensor)
local _, _, co2, temp = string.find(usb_sensor,'CO2:[ ]+([0-9\.]+)[ ]+T:[ ]+([0-9\.]+)')
print(co2.." "..temp)
--if co2 & temp then

--co2     = 0
uptime  = os.capture("cat /proc/uptime | awk -F' ' '{print $1}' | awk -F'.' '{print $1}'")
voltage = os.capture('vcgencmd measure_volts | grep -o "[0-9\.]*"')
----------------------------------------------


--[[            The simple way            ]]--
-- Man kann, falls man keine JSON lib hat,  --
-- den String natürlich selbst aufbauen.    --
-- das funktioniert für einen einzelnen     --
-- Sensor noch relativ gut, für mehrere aber--
-- eher weniger                             --
----------------------------------------------
id                        = "xxx0989xxx"  -- Sollte bestehen aus a-z und 0-9 und 12(?) Zeichen.
stationname               = "xxxx_CO2"   -- Bitte sinnig wählen. ;-)
rasperry_temp_sensorname  = "CPU"           -- Ebenfalls. ;-)
temp_sensorname           = "RoomTemp_01"   -- Ebenfalls. ;-)
co2_sensorname            = "RoomCO2_01"           -- Na wie wohl ;-)


sensordata = '{"version":"0.3","id":"'..id..'","nickname":"'..stationname..'",'..
             '"sensors":{"temperature":[{"name":"'..temp_sensorname..'","value":'..temp..',"unit":"deg"}],"co2":[{"name":"'..co2_sensorname..'","value":'..co2..',"unit":"ppm"}]},'..
             '"system":{"voltage":'..voltage..',"timestamp":0,"uptime":'..uptime..',"heap":0}}'

sensordata = string.gsub(sensordata, "[\n\r]+", "")  -- Wir entfernen jeden Zeilenumbruch im Sensors Objekt, denn rcon ist Zeilenbasiert
----------------------------------------------



--[[           The network stuff          ]]--
----------------------------------------------
rcon_host = socket.dns.toip(rcon_host)   -- Wir lösen erst mal den hostnamen auf.
rcon      = socket.udp()                 -- Erstellen einen UDP Socket.
rcon:setpeername(rcon_host, rcon_port)   -- Und sagen ihm, wohin er gehen soll.

-- Ok, dann schicken wir mal unser rcon paket für Sensoren.
-- Die Syntax dafür lautet:
--      user:secret setsensors sensordata
-- Wobei sensordata das JSON Objekt enthält, dass wir weiter oben gebaut haben.
rcon:send(rcon_user..":"..rcon_secret.." setsensors "..sensordata)

rcon:settimeout(10)   -- Wir setzen den Socket Timeout auf 10 Sekunden
data = rcon:receive() -- Um Anschließend nicht länger als 10 Sekunden auf eine mögliche Antwort zu warten.

if data then          -- Sollte eine Antwort vorliegen, zeigen wir sie nun an und beenden das Programm.
  print(data)
end
----------------------------------------------
