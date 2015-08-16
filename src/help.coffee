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
				if msg.chat.title?
					opt = 'Full help disabled in groups. Please send help command via private chat.'
				else
					(opt += "/#{h.cmd} #{h.args}\n#{h.des}\n\n" if !h.debug) for h in help
			else
				(opt = "/#{h.cmd} #{h.args}\n#{h.des}" if h.cmd == cmd) for h in help
				opt = "Helpless" if opt == ''
			telegram.sendMessage msg.chat.id, opt
	,
		cmd: 'father'
		num: 0
		desc: 'Generate command string for @botfather. Send this string to @botfather via /setcommands'
		debug: yes
		act: (msg) =>
			opt = ''
			(opt += "#{h.cmd} - #{h.args} #{h.des.split('\n')[0]}\n" if !h.debug) for h in help
			telegram.sendMessage msg.chat.id, opt
	,
		cmd: 'module'
		num: 1
		opt: 1
		desc: 'Get module info. If no arguments passed, print loaded modules'
		act: (msg, module) =>
			opt = ''
			if !module?
				opt += 'Loaded modules:\n\n'
				opt += "#{(require m).name}\n" for m in config.modules
				opt += '\nSend /module [name] to get description of a module'
			else
				(opt = "#{(require m).desc}" if (require m).name == module) for m in config.modules
				opt = 'Not found' if opt == ''
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
