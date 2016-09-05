rpio = require 'rpio'
http = require "http"
express = require "express"
app = express()

motorPin = 12

rpio.open motorPin, rpio.PWM
rpio.pwmSetClockDivider 8
rpio.pwmSetRange motorPin, 8192

rpio.pwmSetData motorPin, 8192

speed = 8192

app.get "/stop", (req, res) -> 
	rpio.pwmSetData motorPin, 8192
	res.end "Stopped"
app.get "/faster", (req, res) ->
	speed = speed / 1.25 
	speed = Math.max speed, 0
	speed = Math.min speed, 1024
	rpio.pwmSetData motorPin, speed
	res.end "Speeding Up to #{1/speed}"
app.get "/slower", (req, res) ->
	speed = speed * 1.25
	speed = Math.max speed, 0
	speed = Math.min speed, 1024
	rpio.pwmSetData motorPin, speed
	res.end "Slowing down to #{1/speed}"

server = http.createServer app
server.listen 8000, ->
	console.log "Listenting on port 8000"
