--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local snapchat = {}
local mattata = require('mattata')
local url = require('socket.url')

function snapchat:init()
    snapchat.commands = mattata.commands(self.info.username)
    :command('snapchat')
    :command('snap')
    :command('sc').table
    snapchat.help = '/snapchat <Snapchat username> - Sends the "Snap" code for the given Snapchat username. Aliases: /snap, /sc.'
end

function snapchat:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input
    then
        return mattata.send_reply(
            message,
            snapchat.help
        )
    end
    if input:match('^%@')
    then
        input = input:gsub('^%@', '')
    end
    local success = mattata.send_photo(
        message.chat.id,
        'https://feelinsonice-hrd.appspot.com/web/deeplink/snapcode?type=PNG&size=1000&username=' .. url.escape(input)
    )
    if not success
    then
        return mattata.send_reply(
            message,
            language['errors']['results']
        )
    end
end

return snapchat

