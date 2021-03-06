--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local sed = {}
local mattata = require('mattata')
local json = require('dkjson')

function sed:init()
    sed.commands = { '^%/?[sS]%/.-%/.-%/?$' }
    sed.help = '/s/<pattern>/<substitution> - Replaces all occurences, of text matching a given Lua pattern, with the given substitution.'
end

function sed:on_callback_query(callback_query, message, configuration, language)
    if not message.reply
    then
        return
    end
    if mattata.is_global_admin(callback_query.from.id)
    then
        callback_query.from = message.reply.from
    end
    if message.reply.from.id ~= callback_query.from.id
    then
        return
    end
    local output = string.format(
        '<b>%s:</b>\n%s',
        message.text:match('^(.-):'),
        message.text:match(':\n(.-)$')
    )
    if callback_query.data:match('^no$')
    then
        output = string.format(
            language['sed']['1'],
            output,
            mattata.escape_html(callback_query.from.first_name)
        )
    elseif callback_query.data:match('^yes$')
    then
        output = string.format(
            language['sed']['2'],
            output,
            mattata.escape_html(callback_query.from.first_name)
        )
    elseif callback_query.data:match('^maybe$')
    then
        output = string.format(
            language['sed']['3'],
            output,
            mattata.escape_html(callback_query.from.first_name)
        )
    end
    return mattata.edit_message_text(
        message.chat.id,
        message.message_id,
        output,
        'html'
    )
end

function sed:on_message(message, configuration, language)
    message.text = message.text:gsub('\\%/', '%%fwd_slash%%')
    local matches, substitution = message.text:match('^%/?[sS]%/(.-)%/(.-)%/?$')
    if not substitution
    or not message.reply
    then
        return
    elseif message.reply.from.id == self.info.id
    then
        return mattata.send_reply(
            message,
            language['sed']['4'],
            'html'
        )
    end
    matches = matches:gsub('%%fwd%_slash%%', '/')
    substitution = substitution
    :gsub('\\n', '\n')
    :gsub('\\/', '/')
    :gsub('\\1', '%%1')
    local success, output = pcall(
        function()
            return message.reply.text:gsub(matches, substitution)
        end
    )
    if not success
    then
        return mattata.send_reply(
            message,
            string.format(
                language['sed']['5'],
                mattata.escape_html(matches)
            ),
            'html'
        )
    end
    output = mattata.trim(output)
    return mattata.send_message(
        message.chat.id,
        string.format(
            language['sed']['6'],
            mattata.escape_html(message.reply.from.first_name),
            mattata.escape_html(output)
        ),
        'html',
        true,
        false,
        message.reply.message_id,
        mattata.inline_keyboard():row(
            mattata.row()
            :callback_data_button(
                language['sed']['7'],
                'sed:yes'
            )
            :callback_data_button(
                language['sed']['8'],
                'sed:no'
            )
            :callback_data_button(
                language['sed']['9'],
                'sed:maybe'
            )
        )
    )
end

return sed