rpio = require 'rpio'
http = require "http"
express = require "express"
bodyParser = require "body-parser"
app = express()
jsonParser = bodyParser.json()
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
	pwmValue = Math.min pwmValue, 8192
	rpio.pwmSetData motorPin, pwmValue
	newSpeed = 1000/pwmValue
	console.log "Set speed to #{newSpeed}"
	newSpeed

app.post "/motor/stop", (req, res) ->
	setSpeed(8192)
	res.end "Stopped"
app.post "/motor/faster", (req, res) ->
	newSpeed = setSpeed(pwmValue / 1.25)
	res.end "Speeding Up to #{newSpeed}"
app.post "/motor/slower", (req, res) ->
	newSpeed = setSpeed(pwmValue * 1.25)
	res.end "Slowing down to #{newSpeed}"
app.post "/motor", jsonParser, (req, res, next) ->
	{newPwmValue} = req.body
	if !newPwmValue?
		console.error "Request: #{req.body}"
		return next "Must pass in newPwmValue in JSON"
	newSpeed = setSpeed newPwmValue
	res.end JSON.stringify message: "Setting speed to #{newSpeed}"
app.set('view engine', 'jade')
app.use '/lib', express.static "#{__dirname}/lib"
app.use '/public', express.static "#{__dirname}/public"
app.get '/', (req, res) -> res.render 'index', {title: "Home"}

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
				connection.sendUTF "Slowing down to #{newSpeed}"
			when "stop"
				setSpeed(8192)
				connection.sendUTF "Stopped"
			else
				console.error "Unknown Command", message
				connection.sendUTF "Unknown Command: #{payload}"
	connection.on 'close', ->
		setSpeed 8192

	stateConnection = request.accept 'state', request.origin
	sendMotorState = ->
		motorState = {pwmValue, speed: 1000/pwmValue}
		stateConnection.sendUTF JSON.stringify motorState
	stateConnection.sendUTF
	stateConnection.on 'message', (message) ->
		payload = message.utf8Data
		if payload == "getState"
			sendMotorState()
	stateConnection.on 'connect', sendMotorState
