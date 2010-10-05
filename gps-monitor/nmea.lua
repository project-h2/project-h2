-- This lua module implements a parser of the NMEA0183 standard

-- * Each message's starting character is a dollar sign.
-- * The next five characters identify the talker (two characters) and the type
--   of message (three characters).
-- * All data fields that follow are comma-delimited.
-- * Where data is unavailable, the corresponding field contains NUL bytes
--   (e.g., in "123,,456", the second field's data is unavailable).
-- * The first character that immediately follows the last data field character
--   is an asterisk.
-- * The asterisk is immediately followed by a two-digit checksum representing
--   a hex number. The checksum is the exclusive OR of all characters between
--   the $ and *. According to the official specification, the checksum is
--   optional for most data sentences, but is compulsory for RMA, RMB, and RMC
--   (among others).
-- * <CR><LF> ends the message.

-- As an example, a waypoint arrival alarm has the form:

-- $GPAAM,A,A,0.10,N,WPTNME*32

-- where:
-- GP 	Talker ID (GP for a GPS unit, GL for a GLONASS)
-- AAM 	Arrival alarm
-- A 	Arrival circle entered
-- A 	Perpendicular passed
-- 0.10 	Circle radius
-- N 	Nautical miles
-- WPTNME 	Waypoint name
-- *32 	Checksum data

-- GPS sentence types
-- $GPAAM - Waypoint Arrival Alarm
-- $GPALM - GPS Almanac Data
-- $GPAPA - Autopilot Sentence "A"
-- $GPAPB - Autopilot Sentence "B"
-- $GPASD - Autopilot System Data
-- $GPBEC - Bearing & Distance to Waypoint, Dead Reckoning
-- $GPBOD - Bearing, Origin to Destination
-- $GPBWC - Bearing & Distance to Waypoint, Great Circle
-- $GPBWR - Bearing & Distance to Waypoint, Rhumb Line
-- $GPBWW - Bearing, Waypoint to Waypoint
-- $GPDBT - Depth Below Transducer
-- $GPDCN - Decca Position
-- $GPDPT - Depth
-- $GPFSI - Frequency Set Information
-- $GPGGA - Global Positioning System Fix Data
-- $GPGLC - Geographic Position, Loran-C
-- $GPGLL - Geographic Position, Latitude/Longitude
-- $GPGSA - GPS DOP and Active Satellites
-- $GPGSV - GPS Satellites in View
-- $GPGXA - TRANSIT Position
-- $GPHDG - Heading, Deviation & Variation
-- $GPHDT - Heading, True
-- $GPHSC - Heading Steering Command
-- $GPLCD - Loran-C Signal Data
-- $GPMTA - Air Temperature (to be phased out)
-- $GPMTW - Water Temperature
-- $GPMWD - Wind Direction
-- $GPMWV - Wind Speed and Angle
-- $GPOLN - Omega Lane Numbers
-- $GPOSD - Own Ship Data
-- $GPR00 - Waypoint active route (not standard)
-- $GPRMA - Recommended Minimum Specific Loran-C Data
-- $GPRMB - Recommended Minimum Navigation Information
-- $GPRMC - Recommended Minimum Specific GPS/TRANSIT Data
-- $GPROT - Rate of Turn
-- $GPRPM - Revolutions
-- $GPRSA - Rudder Sensor Angle
-- $GPRSD - RADAR System Data
-- $GPRTE - Routes
-- $GPSFI - Scanning Frequency Information
-- $GPSTN - Multiple Data ID
-- $GPTRF - Transit Fix Data
-- $GPTTM - Tracked Target Message
-- $GPVBW - Dual Ground/Water Speed
-- $GPVDR - Set and Drift
-- $GPVHW - Water Speed and Heading
-- $GPVLW - Distance Traveled through the Water
-- $GPVPW - Speed, Measured Parallel to Wind
-- $GPVTG - Track Made Good and Ground Speed
-- $GPWCV - Waypoint Closure Velocity
-- $GPWNC - Distance, Waypoint to Waypoint
-- $GPWPL - Waypoint Location
-- $GPXDR - Transducer Measurements
-- $GPXTE - Cross-Track Error, Measured
-- $GPXTR - Cross-Track Error, Dead Reckoning
-- $GPZDA - Time & Date
-- $GPZFO - UTC & Time from Origin Waypoint
-- $GPZTG - UTC & Time to Destination Waypoint 

require("rex")
oo = require("loop.multiple")

sentences = {
    GPAAM = "Waypoint Arrival Alarm",
    GPALM = "GPS Almanac Data",
    GPAPA = "Autopilot Sentence A",
    GPAPB = "Autopilot Sentence B",
    GPASD = "Autopilot System Data",
    GPBEC = "Bearing & Distance to Waypoint, Dead Reckoning",
    GPBOD = "Bearing, Origin to Destination",
    GPBWC = "Bearing & Distance to Waypoint, Great Circle",
    GPBWR = "Bearing & Distance to Waypoint, Rhumb Line",
    GPBWW = "Bearing, Waypoint to Waypoint",
    GPDBT = "Depth Below Transducer",
    GPDCN = "Decca Position",
    GPDPT = "Depth",
    GPFSI = "Frequency Set Information",
    GPGGA = "Global Positioning System Fix Data",
    GPGLC = "Geographic Position, Loran-C",
    GPGLL = "Geographic Position, Latitude/Longitude",
    GPGSA = "GPS DOP and Active Satellites",
    GPGSV = "GPS Satellites in View",
    GPGXA = "TRANSIT Position",
    GPHDG = "Heading, Deviation & Variation",
    GPHDT = "Heading, True",
    GPHSC = "Heading Steering Command",
    GPLCD = "Loran-C Signal Data",
    GPMTA = "Air Temperature (to be phased out)",
    GPMTW = "Water Temperature",
    GPMWD = "Wind Direction",
    GPMWV = "Wind Speed and Angle",
    GPOLN = "Omega Lane Numbers",
    GPOSD = "Own Ship Data",
    GPR00 = "Waypoint active route (not standard)",
    GPRMA = "Recommended Minimum Specific Loran-C Data",
    GPRMB = "Recommended Minimum Navigation Information",
    GPRMC = "Recommended Minimum Specific GPS/TRANSIT Data",
    GPROT = "Rate of Turn",
    GPRPM = "Revolutions",
    GPRSA = "Rudder Sensor Angle",
    GPRSD = "RADAR System Data",
    GPRTE = "Routes",
    GPSFI = "Scanning Frequency Information",
    GPSTN = "Multiple Data ID",
    GPTRF = "Transit Fix Data",
    GPTTM = "Tracked Target Message",
    GPVBW = "Dual Ground/Water Speed",
    GPVDR = "Set and Drift",
    GPVHW = "Water Speed and Heading",
    GPVLW = "Distance Traveled through the Water",
    GPVPW = "Speed, Measured Parallel to Wind",
    GPVTG = "Track Made Good and Ground Speed",
    GPWCV = "Waypoint Closure Velocity",
    GPWNC = "Distance, Waypoint to Waypoint",
    GPWPL = "Waypoint Location",
    GPXDR = "Transducer Measurements",
    GPXTE = "Cross-Track Error, Measured",
    GPXTR = "Cross-Track Error, Dead Reckoning",
    GPZDA = "Time & Date",
    GPZFO = "UTC & Time from Origin Waypoint",
    GPZTG = "UTC & Time to Destination Waypoint",
}

require("DataDumper")
function dump(...)
    print(DataDumper(...), "\n---")
end


function parseNMEA(sentence)
    -- match checksum, does not have to be there
    checksum = rex.match(sentence, "\\*([A-F0-9]{2})$")
    if checksum == nil then
        print("Checksum missing")
    else
        print("Checksum", checksum)
    end
    -- is the sentence name valid?
    title = rex.match(sentence, "^\\$(GP[A-Z]{3}),")
    if sentences[title] == nil then
        print("Invalid NMEA0183 sentence")
    else
        print(sentences[title])
    end
    print("Title", title)
    print("----------")
    return(rex.gmatch(sentence, "\\$GPGLL,(\\d+\\.\\d+),([N|S]),(\\d+\\.\\d+),([E|W])(,(\\d+),(\\w+),(\\*[A-F0-9{2}]))*$"))
    --return(rex.split(sentence, ","))
end

for lat, ns, lon, ew in parseNMEA("$GPGLL,5133.81,N,00042.25,W*75") do
    print(lat,ns)
    print(lon,ew)
end
