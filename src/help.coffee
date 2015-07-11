{config} = require './launcher'
telegram = require './telegram'

help = []

help.push
	cmd: 'help'
	args: '[command]'
	des: 'Get help for [command]. If no arguments passed, print the full help string'

for mod in config.modules
	module = require mod
	if module.help
		help.push h for h in module.help

exports.handle = (msg, args) ->
	opt = ''
	if args.length == 0
		for h in help
			if !h.debug
				opt += "/#{h.cmd} #{h.args}\n#{h.des}\n\n"
	else
		for h in help
			if h.cmd == args[0]
				opt += "/#{h.cmd} #{h.args}\n#{h.des}"
		opt = 'Helpless' if opt == ''
	telegram.sendMessage msg.chat.id, opt

