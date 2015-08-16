exports.parse = (cmd) ->
	if !cmd?
		return []

	options = []
	arr = cmd.split(" ")
	opt = ""
	concat = no
	for str, i in arr
		continue if str == ""

		if str.startsWith '"'
			concat = yes
			str = str[1..]
		else if str.endsWith '"'
			concat = no
			options.push opt + str[0..-2]
			opt = ""
			continue

		if !concat
			options.push str
		else
			opt += str + " "
	options

exports.parseConfig = ->
	if process.argv.length >= 3
		file = process.argv[2]
		config = require file
		if !config? or !config.key? or !config.name? or !config.baseurl? or !config.modules?
			no
		if !config.port?
			config.port = 2333
		if !config.memcached?
			config.memcached = '127.0.0.1:11211'
		if !config.workers?
			config.workers = 4
		config

	else
		no
		
