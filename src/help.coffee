{config} = require './launcher'
telegram = require './telegram'

help = []

exports.info = [
		cmd: 'help'
		args: '[command]'
		num: -1
		desc: 'Get help for [command]. If no arguments passed, print the full help string'
		act: (msg, args) =>
			opt = ''
			if args.length == 0
				(opt += "/#{h.cmd} #{h.args}\n#{h.des}\n\n" if !h.debug) for h in help
			else
				(opt = "/#{h.cmd} #{h.args}\n#{h.des}" if h.cmd == args[0]) for h in help
				opt = "Helpless" if opt == ''
			telegram.sendMessage msg.chat.id, opt
]

exports.add = (info) ->
	for i in info
		h =
			cmd: i.cmd
			args: i.args
			des: i.desc
			debug: i.debug
		help.push h

