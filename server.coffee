rpio = require 'rpio'
http = require "http"
express = require "express"
app = express()
WebSocketServer = require('websocket').server

motorPin = 12

rpio.open motorPin, rpio.PWM
rpio.pwmSetClockDivider 8
rpio.pwmSetRange motorPin, 8192

rpio.pwmSetData motorPin, 8192

pwmValue = 8192

setSpeed = (newPwmValue) ->
	pwmValue = newPwmValue
	pwmValue = Math.max pwmValue, 0
	pwmValue = Math.min pwmValue, 1024
	rpio.pwmSetData motorPin, pwmValue
	newSpeed = 1000/pwmValue
	console.log "Set speed to #{newSpeed}"
	newSpeed

app.get "/stop", (req, res) -> 
	rpio.pwmSetData motorPin, 8192
	res.end "Stopped"
app.get "/faster", (req, res) ->
	newSpeed = setSpeed(pwmValue / 1.25)
	res.end "Speeding Up to #{newSpeed}"
app.get "/slower", (req, res) ->
	newSpeed = setSpeed(pwmValue * 1.25)
	res.end "Slowing down to #{1/newSpeed}"

server = http.createServer app
server.listen 8000, ->
	console.log "Listenting on port 8000"

webSocketServer = new WebSocketServer {httpServer: server, autoAcceptConnections: false}

webSocketServer.on 'request', (request) ->
	connection = request.accept '', request.origin
	console.log "#{new Date()} Connected"
	connection.on 'message', (message) ->
		payload = message.utf8Data
		switch payload
			when "faster"
				newSpeed = setSpeed(pwmValue / 1.25)
				connection.sendUTF "Speeding Up to #{newSpeed}"
			when "slower"
				newSpeed = setSpeed(pwmValue * 1.25)
				connection.sendUTF "Slowing down to #{1/newSpeed}"
			when "stop"
				rpio.pwmSetData motorPin, 8192
				connection.sendUTF "Stopped"
			else
				console.error "Unknown Command", message
				connection.sendUTF "Unknown Command: #{payload}"
	connection.on 'close', ->
		setSpeed 8192
