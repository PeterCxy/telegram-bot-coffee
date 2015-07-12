reflekt = require 'reflekt'

{config} = require './launcher'
telegram = require './telegram'

help = []

exports.info = [
		cmd: 'help'
		num: 1
		opt: 1
		desc: 'Get help for a command. If no arguments passed, print the full help string'
		act: (msg, cmd) =>
			opt = ''
			if !cmd?
				(opt += "/#{h.cmd} #{h.args}\n#{h.des}\n\n" if !h.debug) for h in help
			else
				(opt = "/#{h.cmd} #{h.args}\n#{h.des}" if h.cmd == cmd) for h in help
				opt = "Helpless" if opt == ''
			telegram.sendMessage msg.chat.id, opt
]

exports.add = (info) ->
	for i in info
		h =
			cmd: i.cmd
			args: if i.args then i.args else parseArgs i
			des: i.desc
			debug: i.debug
		help.push h

parseArgs = (info) ->
	str = ''
	args = reflekt.parse info.act
	if args.length > 1
		opt = if info.opt then info.opt else 0
		for arg, i in args[1...]
			str += if i < info.num - opt
				"<#{arg}> "
			else
				"[#{arg}] "
	str.trim()
