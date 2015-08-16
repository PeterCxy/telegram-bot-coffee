request = require 'request'
reflekt = require 'reflekt'
{korubaku} = require 'korubaku'

telegram = require './telegram'
store = require './store'
parser = require './parser'
{config}= require './launcher'

routes = []

exports.route = route = (info) ->
	for i in info
		r =
			command: i.cmd
			numArgs: i.num
			optArgs: if i.opt then i.opt else 0
			typing: if i.typing then i.typing else no
			handler: i.act
		routes.push r

# grabInput: if set, all inputs except commands will be send to [module] (exports.input)
# cmd is the command that triggered input grabbing, will be passed to the handler
exports.grabInput = (chat, from, module, cmd) ->
	korubaku (ko) =>
		# Tag fields with chat and from id
		yield store.put 'grab', "#{chat}module#{from}", module, ko.default()
		yield store.put 'grab', "#{chat}cmd#{from}", cmd, ko.default()
		console.log "Input successfully grabbed to #{module}.#{cmd}"

exports.releaseInput = releaseInput = (chat, from) ->
	korubaku (ko) =>
		yield store.put 'grab', "#{chat}module#{from}", '', ko.default()
		yield store.put 'grab', "#{chat}cmd#{from}", '', ko.default()

isCommand = (arg, cmd) ->
	if (arg.indexOf '@') > 0
		[command, username] = arg.split '@'
		command == cmd and username == config.name
	else
		arg == cmd

exports.handleMessage = handleMessage = (msg) ->
	korubaku (ko) =>
		console.log "Handling message " + msg.message_id
		options = parser.parse msg.text
		cmd = if options[0].startsWith '/' then options[0][1...] else ''
		console.log 'Command: ' + cmd
		handled = no
		for r in routes
			if isCommand cmd, r.command
				yield telegram.sendChatAction msg.chat.id, 'typing', ko.default() if r.typing
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
		# Try to distribute it to the input grabber or default processor
		if !handled
			m = yield store.get 'grab', "#{msg.chat.id}module#{msg.from.id}", ko.default()
			if m? and m != ''
				console.log "Input is grabbed by #{m}"
				cmd = yield store.get 'grab', "#{msg.chat.id}cmd#{msg.from.id}", ko.default()
				console.log "Input is grabbed to #{cmd}"
				# In the module that grabs input
				# Should contain a function
				# exports.setup = (cmd, msg, telegram, store, server, config) -> ...
				# cmd is the trigger command of the whole event
				(require m).input cmd, msg, telegram, store, exports, config if cmd? and cmd != ''
			else if config.default? and
					(msg.text.startsWith("@#{config.name}") or
					!msg.chat.title? or config.default_no_prefix or
					msg.reply_to_message.from.username is config.name)

				console.log "Default processor: #{config.default}"
				(require config.default).default msg, telegram, store, exports, config
			else
				console.log 'Nothing done for ' + cmd

exports.handleRequest = (req, res, next) ->
	console.log req.params if req.params
	handleMessage req.params.message if req.params.update_id
	res.writeHead 200
	console.log '---- Request end ----'
	res.end()
	next()

# The cancel command
exports.info = [
		cmd: 'cancel'
		num: 0
		desc: 'Cancel the current session'
		act: (msg) ->
			releaseInput msg.chat.id, msg.from.id
			for m in config.modules
				mod = require m
				
				console.log "calling cancel of #{m} #{mod.cancel?}"
				mod.cancel msg, telegram, store, exports, config if mod.cancel?
			telegram.sendMessage msg.chat.id, 'Current session interrupted.', null,
				telegram.makeHideKeyboard()
]
