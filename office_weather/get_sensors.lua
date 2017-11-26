#!/usr/bin/lua

--[[           Moduleinbindung            ]]--
----------------------------------------------
status, socket = pcall(require, "socket")
if not status then
  print("Bitte Socket Erweiterung installieren.")
  print("sudo apt-get install lua-socket")
  os.exit(1)
end

status, http = pcall(require, "socket.http")
if not status then
  print("Bitte HTTP Erweiterung installieren.")
  os.exit(1)
end

status, json = pcall(require, "json")
if not status then
  print("Bitte JSON Erweiterung installieren.")
  os.exit(1)
end

----------------------------------------------


--[[                Config                ]]--
----------------------------------------------
url          = "http://luftwache.devbot.de/sensors.json"
remote       = true
http.TIMEOUT = 8
colormode    = "term-16"
format       = "fixed" -- alternativ, free
----------------------------------------------



function setColormode(mode)
  if mode == "irc" then
    RST_ALL           = "\15"
    BOLD              = "\2"
    BOLD_RST          = "\2"
    ITALIC            = "\22"
    UNDERLINE         = "\31"
    UNDERLINE2        = "\37"            -- ???????
    COL               = "\3"
    COL_NULL          = BOLD..BOLD_RST   -- Hack, to avoid collisions with userinput on irc
    COL_RST           = COL..COL_NULL
    COL_RED           = COL.."04"
    COL_GREEN         = COL.."09"
    COL_YELLOW        = COL.."08"
    COL_ORANGE        = COL.."07"
    COL_CYAN          = COL.."11"
    COL_RED_ON_YELLOW = COL.."04,08"

  elseif mode == "term-16" then
    RST_ALL           = "\27[0m"
    BOLD              = "\27[1m"
    BOLD_RST          = "\27[0m"
    COL_NULL          = ""               -- Hack, to avoid collisions with userinput on irc


    COL_RED           = "\27[31m"
    COL_GREEN         = "\27[32m"
    COL_ORANGE        = "\27[38;5;18m"
    COL_YELLOW        = "\27[33m"
    COL_RED_ON_YELLOW = "\27[38;5;52m"
    COL_RST           = "\27[39m\27[49m"
    COL_NULL          = ""               -- Hack, to avoid collisions with userinput on irc

  elseif mode == "term-256" then
    RST_ALL           = "\27[0m"
    BOLD              = "\27[1m"
    BOLD_RST          = "\27[0m"
    COL_RED           = "\27[38;5;31m"  -- red 1
    COL_GREEN         = "\27[38;5;17m" -- blue 1
    COL_ORANGE        = "\27[38;5;18m" -- blue 1
    COL_YELLOW        = "\27[38;5;19m" -- blue 1
    COL_RED_ON_YELLOW = "\27[38;5;52m"
    COL_RST           = "\27[39m\27[49m"
    COL_NULL          = "" -- Hack, to avoid collisions with userinput on irc

  end
end

setColormode(colormode)

function get_phalanxes_for_user(user,sensorfile)
  if sensorfile[user] then
    local raw_phalanxes = {}
    for id,phalanx in pairs(sensorfile[user]) do
      raw_phalanxes[id] = phalanx
    end
    return raw_phalanxes
  end
end

function read_sensor_file()
  sensorfile,err = io.open("/tmp/sensors.json")
  if err then print("Can't open sensor file."); return; end
  data = sensorfile:read()
  local status,sensordata = pcall(json.decode, data)
  if status and sensordata then
    return sensordata
  else
    return false
  end
end

function read_sensor_file_remote(url)
  local data = {}
  body, code, header = http.request(url)
  if code ~= 200 then
    print("!!ERROR!! Can't load sensor file: CODE:"..code)
    return nil
  end
  local status,sensordata = pcall(json.decode, body)
  if status and sensordata then
    return sensordata
  else
    return false
  end
end



function print_phalanx_free_format(phalanx)
 local phalanx = phalanx
 local report  = ""
 for sensorclass,sensor in pairs(phalanx["sensors"]) do
   for key,sensor in ipairs(sensor) do
     report = report..sensor["name"].."\n"
   end
 end
 return report
end


function print_phalanx(phalanx)
 local phalanx = phalanx
 local report  = ""
 report = report..string.format(BOLD.."%-20s"..BOLD_RST..COL_GREEN..BOLD.." >>> "..COL_RST..BOLD_RST,phalanx["nickname"])

 if phalanx["sensors"] and phalanx["sensors"]["temperature"] then
   report = report..string.format("Temperatur:  ")
   for key,sensor in ipairs(phalanx["sensors"]["temperature"]) do
     report = report..string.format(""..BOLD.."%-23s"..BOLD_RST..": "..BOLD.."%5s %s"..BOLD_RST.." " ,sensor["name"], sensor["value"], sensor["unit"])
   end
   report = report..string.format("\n")
   newline = true
 end

 
 if phalanx["sensors"] and phalanx["sensors"]["humidity"] then
   if newline then
     report = report.."                     "..COL_GREEN..BOLD..">>>"..COL_RST..BOLD_RST.." "
   end
   report = report..string.format("Luftfeuchte: ")
   for key,sensor in ipairs(phalanx["sensors"]["humidity"]) do
     report = report..string.format(""..BOLD.."%-23s"..BOLD_RST..": "..BOLD.."%5s %s"..BOLD_RST.." " ,sensor["name"], sensor["value"], sensor["unit"])
   end
   report = report..string.format("\n")
   newline = true
 end


 if phalanx["sensors"] and phalanx["sensors"]["dewpoint"] then
   if newline then
     report = report.."                     "..COL_GREEN..BOLD..">>>"..COL_RST..BOLD_RST.." "
   end
   report = report..string.format("Taupunkt:    ")
   for key,sensor in ipairs(phalanx["sensors"]["dewpoint"]) do
     report = report..string.format(""..BOLD.."%-23s"..BOLD_RST..": "..BOLD.."%5s %s"..BOLD_RST.." " ,sensor["name"], sensor["value"], sensor["unit"])
   end
   report = report..string.format("\n")
   newline = true
 end

 if phalanx["sensors"] and phalanx["sensors"]["windspeed"] then
   if newline then
     report = report.."                     "..COL_GREEN..BOLD..">>>"..COL_RST..BOLD_RST.." "
   end
   report = report..string.format("Wind:        ")
   for key,sensor in ipairs(phalanx["sensors"]["windspeed"]) do
     report = report..string.format(""..BOLD.."%-23s"..BOLD_RST..": "..BOLD.."%5s %s"..BOLD_RST.." " ,sensor["name"], sensor["value"], sensor["unit"])
   end
   report = report..string.format("\n")
   newline = true
 end

 if phalanx["sensors"] and phalanx["sensors"]["windvane"] then
   if newline then
     report = report.."                     "..COL_GREEN..BOLD..">>>"..COL_RST..BOLD_RST.." "
   end
   report = report..string.format("Windrichtung:")
   for key,sensor in ipairs(phalanx["sensors"]["windvane"]) do
     report = report..string.format(""..BOLD.."%-23s"..BOLD_RST..": "..BOLD.."%5s %s"..BOLD_RST.." " ,sensor["name"], sensor["value"], sensor["unit"])
   end
   report = report..string.format("\n")
   newline = true
 end


 if phalanx["sensors"] and phalanx["sensors"]["pressure"] then
   if newline then
     report = report.."                     "..COL_GREEN..BOLD..">>>"..COL_RST..BOLD_RST.." "
   end
   report = report..string.format("Luftdruck:   ")
   for key,sensor in ipairs(phalanx["sensors"]["pressure"]) do
     report = report..string.format(""..BOLD.."%-23s"..BOLD_RST..": "..BOLD.."%5s %s"..BOLD_RST.." " ,sensor["name"], sensor["value"], sensor["unit"])
   end
   report = report..string.format("\n")
   newline = true
 end

  if phalanx["sensors"] and phalanx["sensors"]["co2"] then
   if newline then
     report = report.."                     "..COL_GREEN..BOLD..">>>"..COL_RST..BOLD_RST.." "
   end
   report = report..string.format("CO2:         ")
   for key,sensor in ipairs(phalanx["sensors"]["co2"]) do
     report = report..string.format(""..BOLD.."%-23s"..BOLD_RST..": "..BOLD.."%5s %s"..BOLD_RST.." " ,sensor["name"], sensor["value"], sensor["unit"])
   end
   report = report..string.format("\n")
   newline = true
 end

 if phalanx["system"] then
   if newline then
     report = report.."                     "..COL_RED..BOLD..">>>"..COL_RST..BOLD_RST.." "
   end
   report = report.."Lastsignal:  "..BOLD..os.time()-phalanx["lastsignal"]..BOLD_RST.."s "
   report = report.."Uptime: "..BOLD..phalanx["system"]["uptime"]..BOLD_RST.." "
   report = report.."Heap: "..BOLD..phalanx["system"]["heap"]..BOLD_RST.." "
  -- report = report.."Free Filesystem: "..BOLD..(phalanx["system"]["filesystem"]["remaining"] or "N/A")..BOLD_RST.." Bytes "
   report = report.."Voltage: "..BOLD..phalanx["system"]["voltage"]..BOLD_RST.." "
   report = report..string.format("\n")
   newline = true
 end
 return report
end





if remote then
  sensorfile = read_sensor_file_remote(url)
else
  sensorfile = read_sensor_file()
end
report     = ""


for key, parm in ipairs(arg) do
  if parm == "color:term" then
    setColormode("term-16")
  elseif parm == "color:irc" then
    setColormode("irc")
  elseif parm == "format:free" then
    format = "free"
  end
end

if arg[1] then
  parm1=arg[1]
  if parm1 == "showall" then
    for username,phalanxes in pairs(sensorfile) do
      --report = report..username.."\n"
      for id,phalanx in pairs(phalanxes) do
        report = report .. print_phalanx(phalanx)      
      end
    end
    print(report)
    os.exit()
  else
    phalanxes = get_phalanxes_for_user(parm1,sensorfile)
    if not phalanxes then
      print("No such user.")
      os.exit()
    else
      for id,phalanx in pairs(phalanxes) do
        if format == "free" then
          report = report .. print_phalanx_free_format(phalanx)
        else
          report = report .. print_phalanx(phalanx)
        end
      end
      print(report)
      os.exit()
    end
  end
end

os.exit()
