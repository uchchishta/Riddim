local parse_xkcd_list;
local xkcd_list_updated_at = 0;
local xkcd_list = { };

function riddim.plugins.xkcd(bot)
	require "net.httpclient_listener";
	local http = require("net.http");
	bot:hook("commands/xkcd", function(command)
		if os.difftime(os.time(), xkcd_list_updated_at) > (3 * 60 * 60) then -- Not refreshed within 3 hours
			http.request('http://xkcd.com/archive/', {
					headers = { ["If-Modified-Since"] = os.date("!%a, %d %b %Y %T %Z", xkcd_list_updated_at or 0) }
				}, function (data, code)
				if code == 200 then
					xkcd_list_updated_at = os.time();
					print("debug", "got "..(#data or 0).." bytes of data");
					parse_xkcd_list(data);
				elseif code == 304 then
					xkcd_list_updated_at = os.time();
				else
					if code > 0 then
						command:reply("Received HTTP "..code.." error trying to fetch the XKCD archive");
					else
						command:reply("Unable to fetch the XKCD archive from xkcd.com: "..data:gsub("%-", " "));
					end
					return;
				end
				command:reply(handle_xkcd_command(command));
			end);
		else
			return handle_xkcd_command(command);
		end
	end);
end

function handle_xkcd_command(command)
		local xkcdnum = command.param;
		if not xkcdnum then return "Please supply an XKCD number or a search string :)"; end
			if not tonumber(xkcdnum) then -- Search for an xkcd
				local results = {};
				for x, xkcd in pairs(xkcd_list) do
					name = " "..xkcd:lower().." ";
					if name:match(xkcdnum:lower():gsub("%-", "%%-")) then
						table.insert(results, x);
						--return commands.xkcd(msg, x);
					end
				end
				if #results == 0 then
					return "Sorry, I couldn't find a match";
				elseif #results == 1 then
					command.param = results[1];
					return handle_xkcd_command(command);
				else
					-- We have more than one match
					local ret = "Multiple matches:";
					for _, x in ipairs(results) do
						local xkcdnum = tostring(tonumber(x));
						local xkcd = xkcd_list[tostring(x)];
						ret = string.format("%s %s%s", ret, xkcd, ((_ < #results) and ",") or "");
						if _ > 5 then ret = ret .. " " .. (#results - 5) .. " more"; break; end
					end
					return ret;
				end
			end
			-- Check that xkcdnum is a valid number
			xkcdnum = tostring(tonumber(xkcdnum));
			if not xkcdnum then return "What XKCD strip number? Or enter a search string."; end
			xkcd = xkcd_list[xkcdnum];
			if not xkcd then return "Sorry, I don't think there is a XKCD #"..xkcdnum; end
			return xkcd..", http://xkcd.org/"..xkcdnum.."/";
end

function parse_xkcd_list(t)
	if not t then return nil; end
	for number, name in string.gmatch(t,"<a [^>]*href=\"/(%d+)/\"[^>]*>([^<]+)") do
		xkcd_list[number] = name;
	end
	return true;
end
