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
		res.write "This is Peter's Telegram bot @PeterCxyBot"
		res.writeHead 404
		next()
		res.end()

	server.post "/" + config.key, serv.handleRequest

	# -1: unlimited arguments
	serv.route 'help', -1, help.handle
	for mod in config.modules
		module = require mod
		module.setup telegram, serv, store if module

	if cluster.isMaster
		telegram.setWebhook config.urlbase + "/" + config.key, (error) =>
			if !error
				console.log 'Server registered.'
	else
		server.listen config.port, ->
			console.log 'Server up.'

