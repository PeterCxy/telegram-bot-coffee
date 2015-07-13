telegram-bot-coffee
===

An extendable Telegram Bot implementation written in CoffeeScript. Powered by `node.js` or `io.js`

Configuration
===

On running the main binary `telegram-bot`, a configuration file will be loaded according to the first parameter passed to it via command line.

e.g.  
```shell
telegram-bot /path/to/the/config.json # This is full path!
```

The configuration file should be in `json` format:

```json
{
	"key": "auth-key-from-bot-father",
	"name": "the-username-of-your-bot",
	"urlbase": "https://yoursite.yourdomain/some/path",
	"port": 23326,
	"workers": 4,
	"memcached": "127.0.0.1:11211",
	"modules": [
		"module1",
		"module2"
	]
}
```

`key`: The authorization key you get from Telegram's @BotFather

`name`: The username of your bot (not Name, but UserName)

`urlbase`: The url that your sever could be accessed. Shoud always be an HTTPS address. Note that this program will actually listen at `urlbase/key` to ensure that only Telegram knows this server.  

`port`: The listen port of this bot. You should set up a reverse proxy to forward all request to `some/path` to `127.0.0.1:port`

for example, an Nginx config

```
location /some/path {
	proxy_pass http://127.0.0.1:23326/;
	proxy_set_header Host $host;
	proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

corresponds to the config with `urlbase` = `https://yoursite.yourdomain/some/path` and `port` = `23326`

`memcached`: The `Memcached` server address. The bot needs `Memcached` to store sessions temporarily. Pernament storage is not implemented by default, and should be implemented by modules.

`workers`: Number of worker processes.

`modules`: Modules you want to load with this bot.

Modules
===

Modules are the heart of Telegram bots based on this package.

A module can be:

* An npm package
* A JavaScript which can run on Node.js

To load an npm-packaged module, just install it and add its name to the `modules` array in config file.

To load a JavaScript module, put it somewhere and add its __full path__ to the `modules` array in config file.

All modules in the `modules` array are loaded at start time. If any error occurs, the robot won't work at all.

A module should contain a main file. To an npm-packaged module, it should be the main file of the npm package. To a JavaScript module, it should just be the `.js` script.

The main file should contain:

* `exports.name`: The name of the module. May not be the same as the npm package name. Must be unique.
* `exports.desc`: The description of the module. May not be the same as the npm package description.
* `exports.setup`: The function called on start.

On start, the `setup` function will be called, and two arguments will be passed, `telegram` and `store`. `telegram` is the Telegram Bot API object, the `store` is the `memcached` object. See the source code of this bot for details.

The `setup` function should return an array of `command` objects, e.g. (CoffeeScript object format)

```coffeescript
[
		cmd: 'name-of-the-command'
		args: '[optional] argument list in text format'
		num: total-number-of-arguments
		opt: number-of-optional-arguments-of-the-total-number
		desc: 'description of the command'
		act: (msg, arg1, arg2, ...) ->
			do what you want...
	,
		cmd: 'name-of-the-command'
		args: '[optional] argument list in text format'
		num: number-of-arguments
		opt: number-of-optional-arguments-of-the-total-number
		desc: 'description of the command'
		act: (msg, arg1, arg2, ...) ->
			do what you want...
]
```

`args` is optional. If no `args` provided, the bot will parse the list of arguments in the `act` function (except the first one), and use their names as the argument list.

When the bot receives a command in Telegram, e.g. `/name-of-the-command arg1`, the bot will parse its arguments and try to deliver the message to the corresponding module.
The bot will first check the number of arguments. If `num - opt <= arg_num <= num`, then the `act` function will be called. At least a number of `num - opt` of arguments will be passed. Optinal arguments can be null.

If `num` is `-1`, it means no limit on argument number. The bot will pass a array of arguments to the second param of `act` function instead of expanding the array to actual parameters.

The first argument of `act` function is the `Message` object, the same one as is described in the telegram bot document.

The description may not be explicit enough, see example module projects:

[telegram-bot-examples](https://github.com/PeterCxy/telegram-bot-examples)  
[telegram-bot-pictures](https://github.com/PeterCxy/telegram-bot-pictures)

License
===

Copyright (C) 2014 Peter Cai

telegram-bot-coffee is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

telegram-bot-coffee is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with telegram-bot-coffee.  If not, see <http://www.gnu.org/licenses/>.

