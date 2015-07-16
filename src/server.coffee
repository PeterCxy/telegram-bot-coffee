request = require 'request'
reflekt = require 'reflekt'

telegram = require './telegram'
store = require './store'
parser = require './parser'
{config}= require './launcher'

routes = []

exports.route = (info) ->
	for i in info
		r =
			command: i.cmd
			numArgs: i.num
			optArgs: if i.opt then i.opt else 0
			handler: i.act
		routes.push r

# grabInput: if set, all inputs except commands will be send to [module] (exports.input)
# cmd is the command that triggered input grabbing, will be passed to the handler
exports.grabInput = (chat, from, module, cmd) ->
	# Tag fields with chat and from id
	store.put 'grab', "#{chat}module#{from}", module, (err) =>
		store.put 'grab', "#{chat}cmd#{from}", cmd, (err) =>
			console.log "Input successfully grabbed to #{module}.#{cmd}"

exports.releaseInput = (chat, from) ->
	store.put 'grab', "#{chat}module#{from}", '', (err) ->
		store.put 'grab', "#{chat}cmd#{from}", ''

isCommand = (arg, cmd) ->
	if (arg.indexOf '@') > 0
		[command, username] = arg.split '@'
		command == cmd and username == config.name
	else
		arg == cmd

handleMessage = (msg) ->
	console.log "Handling message " + msg.message_id
	options = parser.parse msg.text
	cmd = if options[0].startsWith '/' then options[0][1...] else ''
	console.log 'Command: ' + cmd
	handled = no
	for r in routes
		if isCommand cmd, r.command
			if r.numArgs >= 0 and r.numArgs >= options.length - 1 >= r.numArgs - r.optArgs
				result = reflekt.parse r.handler
				args = { "#{result[0]}": msg }
				for option, i in options[1...]
					args[result[i + 1]] = option
				console.log args
				reflekt.call r.handler, args
			else if r.numArgs < 0
				r.handler msg, options[1...]
			else
				console.log 'Wrong usage of ' + cmd
				telegram.sendMessage msg.chat.id, "Wrong usage. Consult the /help command for help."
			handled = yes
			break

	# If the current input has not been handled
	# Try to distribute it to the input grabber
	if !handled
		store.get 'grab', "#{msg.chat.id}module#{msg.from.id}", (err, m) =>
			if m? and m != ''
				console.log "Input is grabbed by #{m}"
				store.get 'grab', "#{msg.chat.id}cmd#{msg.from.id}", (err, cmd) =>
					console.log "Input is grabbed to #{cmd}"
					# In the module that grabs input
					# Should contain a function
					# exports.setup = (cmd, msg, telegram, store, server, config) -> ...
					# cmd is the trigger command of the whole event
					(require m).input cmd, msg, telegram, store, exports, config if cmd? and cmd != ''
			else
				console.log 'Nothing done for ' + cmd

exports.handleRequest = (req, res, next) ->
	console.log req.params if req.params
	handleMessage req.params.message if req.params.update_id
	res.writeHead 200
	res.end()
	next()

