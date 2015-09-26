request = require 'request'
{config} = require './launcher'

class Telegram
	constructor: (@auth) ->

	callbackHandler: (error, response, body, callback) =>
		console.log body
		if body
			result = try
				JSON.parse body
			catch err
				null

			if result? and result.ok
				callback null, result
			else
				error = new Error 'result is not okay'
				callback error, result
		else
			callback error, null
	
	post: (method, data, callback) =>
		opts =
			url: 'https://api.telegram.org/bot' + @auth + '/' + method
			form: data
			method: 'POST'
		console.log opts.url
		request opts, (error, response, body) =>
			@callbackHandler error, response, body, callback
	
	# Multipart
	postUpload: (method, data, callback) =>
		opts =
			url: 'https://api.telegram.org/bot' + @auth + "/" + method
			formData: data
		console.log opts.url
		request.post opts, (error, response, body) =>
			@callbackHandler error, response, body, callback
	
	setWebhook: (url, callback) ->
		opts =
			url: url
		@post 'setWebHook', opts, (error, result) =>
			callback error
	
	getUpdates: (offset, callback) ->
		opts =
			offset: offset
			timeout: 15 # For a long polling
		@post 'getUpdates', opts, (error, result) =>
			res = result.result if result? and result.ok
			callback error, res
	
	sendChatAction: (chat, action, callback) ->
		opts =
			chat_id: chat
			action: action
		@post 'sendChatAction', opts, (error, result) =>
			console.log 'chat action sent'
			callback error, result
	
	sendMessage: (chat, text, reply_to, keyboard) ->
		opts =
			chat_id: chat
			text: text
		opts['reply_to_message_id'] = reply_to if reply_to
		opts['reply_markup'] = keyboard if keyboard
		console.log opts
		@post 'sendMessage', opts, (error, result) =>
			console.log "Message sent to #{chat}" if result? and result.ok
	
	getFile: (id, callback) ->
		opts =
			file_id: id

		@post 'getFile', opts, (error, result) =>
			if !error? and result? and result.ok
				callback null, result.result
			else
				callback error, null

	getFileUrl: (path) ->
		"https://api.telegram.org/file/bot#{@auth}/#{path}"

	makeKeyboard: (keyboard, resize, selective) ->
		JSON.stringify
			keyboard: keyboard
			resize_keyboard: if resize? then resize else no
			one_time_keyboard: yes
			selective: if selective? then selective else no
	
	# Make a vertical keyboard with an array
	verticalKeyboard: (array) ->
		ret = []
		ret.push [a] for a in array
		ret

	makeHideKeyboard: (selective) ->
		JSON.stringify
			hide_keyboard: yes
			selective: if selective? then selective else no

uploadStub = (method, name) ->
	(chat, stream, reply_to, callback) ->
		# TODO: Should support file_id
		opts =
			chat_id: chat
			"#{name}": stream
		opts['reply_to_message_id'] = reply_to if reply_to
		@postUpload method, opts, (error, result) =>
			console.log "#{method} succeeded" if result.ok

			callback error, result

uploadMethods = [
		method: "sendPhoto"
		name: "photo"
	,
		method: "sendAudio"
		name: "audio"
	,
		method: "sendVideo"
		name: "video"
	,
		method: "sendDocument"
		name: "document"
	,
		method: "sendSticker"
		name: "sticker"
]

for m in uploadMethods
	Telegram.prototype[m.method] = uploadStub m.method, m.name

module.exports = new Telegram config.key
