require "util.xstanza"

function riddim.plugins.commands(bot)
	local command_pattern = "^%"..(bot.config.command_prefix or "@").."([%a%-%_%d]+)(%s?)(.*)$";

	local function process_command(event)
		local body = event.body;
		if not body then return; end
		if event.delay then return; end -- Don't process old messages from groupchat

		local command, hasparam, param = body:match(command_pattern);
	
		if not command then
			command, hasparam, param = body:match("%[([%a%-%_%d]+)(%s?)(.*)%]");
		end
		
		if hasparam ~= " " then param = nil; end
	
		if command then
			local command_event = {
				command = command,
				param = param,
				sender = event.sender,
				stanza = event.stanza,
				reply = event.reply,
				room = event.room, -- groupchat support
			};
			local ret = bot:event("commands/"..command, command_event);
			if type(ret) == "string" then
				event:reply(ret);
			end
			return ret;
		end
	end
	
	-- Hook messages sent to bot, fire a command event on the bot
	bot:hook("message", process_command);
	
	-- Support groupchat plugin: Hook messages from rooms that the bot joins
	bot:hook("groupchat/joining", function (room)
		room:hook("message", process_command);
	end);
end
