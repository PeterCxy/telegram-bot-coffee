restify = require 'restify'
cluster = require 'cluster'
{korubaku} = require 'korubaku'

config = (require './parser').parseConfig()
exports.config = config

# These modules need config, so load them here
telegram = require './telegram'
serv = require './server'
store = require './store'
help = require './help'

exports.launch = ->

	if !config.webhook
		config.workers = 1

	if cluster.isMaster
		cluster.fork() for i in [1..config.workers]
	
	if config.webhook
		server = restify.createServer
			name: 'telegram-bot'
			version: '1.0.0'

		server.use restify.acceptParser server.acceptable
		server.use restify.queryParser()
		server.use restify.bodyParser()

		server.pre (req, res, next) =>
			console.log "---- Incoming Request ----"
			res.writeHead 200
			res.write 'A Telegram Bot'
			next()
			res.end()

		server.post "/" + config.key, serv.handleRequest

	# Route the help command
	serv.route help.info
	help.add help.info
	for mod in config.modules
		module = require mod

		info = module.setup telegram, store, serv, config

		serv.route info
		help.add info
	# Routhe the cancel command
	serv.route serv.info
	help.add serv.info

	if config.webhook
		if cluster.isMaster
			telegram.setWebhook config.urlbase + "/" + config.key, (error) =>
				if !error
					console.log 'Server registered.'
		else
			server.listen config.port, ->
				console.log 'Server up.'
	else
		if cluster.isMaster
			telegram.setWebhook '', (error) ->
				console.log 'Webhook cleared'
		else
			eventLoop()

# Event loop of long-polling
eventLoop = ->
	korubaku (ko) =>
		offset = yield store.get 'poll', 'offset', ko.default()
		console.log "offset is #{offset}"
		[error, updates] = yield telegram.getUpdates offset + 1, ko.raw()
		if error? or !updates? or updates.length is 0
			newOffset = offset
		else
			newOffset = updates[updates.length - 1].update_id
		console.log "next offset is #{newOffset}"
		yield store.put 'poll', 'offset', newOffset, ko.default()
		
		if !error? and updates?
			for update in updates
				console.log update.message

				if !update.message.from?
					continue

				if !update.message.text?
					update.message.text = ''

				try
					serv.handleMessage update.message
				catch err
					console.log err

		setTimeout ->
			eventLoop()
		, 1000
