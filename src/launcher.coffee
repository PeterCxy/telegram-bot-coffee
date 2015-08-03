restify = require 'restify'
cluster = require 'cluster'

config = (require './parser').parseConfig()
exports.config = config

# These modules need config, so load them here
telegram = require './telegram'
serv = require './server'
store = require './store'
help = require './help'

exports.launch = ->

	if cluster.isMaster
		cluster.fork() for i in [1...config.workers]

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

	if cluster.isMaster
		telegram.setWebhook config.urlbase + "/" + config.key, (error) =>
			if !error
				console.log 'Server registered.'
	else
		server.listen config.port, ->
			console.log 'Server up.'

