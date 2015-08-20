exports.parse = (cmd) ->
	if !cmd?
		return []

	options = []
	arr = cmd.split(" ")
	opt = ""
	concat = no
	endTag = ''
	for str, i in arr
		continue if str == ""

		if !concat
			[result, endTag] = hasStartQuotes str
			if result
				concat = yes
				str = str[1..]

		if concat and (endTag isnt '') and str.endsWith endTag
			concat = no
			options.push opt + str[0..-2]
			opt = ""
			endTag = ''
			continue

		if !concat
			options.push str
		else
			opt += str + " "

	# If concat is still true, just push the current string
	if concat
		options.push str

	options

startTags = [ '"', "'" ]
endTags = [ '"', "'" ]

hasStartQuotes = (str) ->
	endTag = ''
	for tag, i in startTags
		if str.startsWith tag
			endTag = endTags[i]
			break
	[ endTag isnt '', endTag ]

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
