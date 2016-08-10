local preview = {}

local HTTP = require('socket.http')
local utilities = require('mattata.utilities')

preview.command = 'preview <link>'

function preview:init(config)
	preview.triggers = utilities.triggers(self.info.username, config.cmd_pat):t('preview', true).table
	preview.doc = config.cmd_pat .. 'preview <link> \nReturns a full-message, "unlinked" preview.'
end

function preview:action(msg)

	local input = utilities.input(msg.text)

	if not input then
		utilities.send_message(self, msg.chat.id, preview.doc, true, nil, true)
		return
	end

	input = utilities.get_word(input, 1)
	if not input:match('^https?://.+') then
		input = 'http://' .. input
	end

	local res = HTTP.request(input)
	if not res then
		utilities.send_reply(self, msg, 'Please provide a valid link.')
		return
	end

	if res:len() == 0 then
		utilities.send_reply(self, msg, 'Sorry, the link you provided is not letting me generate a preview.')
		return
	end

	local output = '[​](' .. input .. ')'
	utilities.send_message(self, msg.chat.id, output, false, nil, true)

end

return preview
