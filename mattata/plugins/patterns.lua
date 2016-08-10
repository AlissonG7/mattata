local patterns = {}

local utilities = require('mattata.utilities')

patterns.triggers = {
	'^/?s/.-/.-$'
}

function patterns:action(msg)
	if not msg.reply_to_message then return true end
	local output = msg.reply_to_message.text
	if msg.reply_to_message.from.id == self.info.id then
		output = output:gsub('Did you mean:\n"', '')
		output = output:gsub('"$', '')
	end
	local m1, m2 = msg.text:match('^/?s/(.-)/(.-)/?$')
	if not m2 then return true end
	local res
	res, output = pcall(
		function()
			return output:gsub(m1, m2)
		end
	)
	if res == false then
		utilities.send_reply(self, msg, 'Malformed pattern!')
	else
		output = output:sub(1, 4000)
		output = '*Did you mean:*\n"' .. utilities.md_escape(utilities.trim(output)) .. '"'
		utilities.send_reply(self, msg.reply_to_message, output, true)
	end
end

return patterns
