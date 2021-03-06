--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local untrust = {}
local mattata = require('mattata')
local redis = require('mattata-redis')

function untrust:init()
    untrust.commands = mattata.commands(self.info.username):command('untrust').table
    untrust.help = '/untrust [user] - Untrusts a user to a standard user of the current chat. This command can only be used by administrators of a supergroup.'
end

function untrust:on_message(message, configuration, language)
    if message.chat.type ~= 'supergroup'
    then
        return mattata.send_reply(
            message,
            language['errors']['supergroup']
        )
    elseif not mattata.is_group_admin(
        message.chat.id,
        message.from.id,
        true
    )
    then
        return mattata.send_reply(
            message,
            language['errors']['admin']
        )
    end
    local input = message.reply
    and tostring(message.reply.from.id)
    or mattata.input(message.text)
    if not input
    then
        local success = mattata.send_force_reply(
            message,
            language['untrust']['1']
        )
        if success
        then
            redis:set(
                string.format(
                    'action:%s:%s',
                    message.chat.id,
                    success.result.message_id
                ),
                '/untrust'
            )
        end
        return
    elseif tonumber(input) == nil
    and not input:match('^%@')
    then
        input = '@' .. input
    end
    local user = mattata.get_user(input)
    or mattata.get_chat(input) -- Resolve the username/ID to a user object.
    if not user
    then
        return mattata.send_reply(
            message,
            language['errors']['unknown']
        )
    elseif user.result.id == self.info.id
    then
        return
    end
    user = user.result
    local status = mattata.get_chat_member(
        message.chat.id,
        user.id
    )
    if not status
    then
        return mattata.send_reply(
            message,
            language['errors']['generic']
        )
    elseif mattata.is_group_admin(
        message.chat.id,
        user.id
    )
    then -- We won't try and untrust users who are moderators/administrators.
        return mattata.send_reply(
            message,
            language['untrust']['2']
        )
    elseif status.result.status == 'left'
    or status.result.status == 'kicked'
    then -- Check if the user is in the group or not.
        return mattata.send_reply(
            message,
            string.format(
                status.result.status == 'left'
                and language['untrust']['3']
                or language['untrust']['4']
            )
        )
    end
    redis:srem(
        'administration:' .. message.chat.id .. ':trusted',
        user.id
    )
    if redis:hget(
        string.format(
            'chat:%s:settings',
            message.chat.id
        ),
        'log administrative actions'
    )
    then
        mattata.send_message(
            mattata.get_log_chat(message.chat.id),
            string.format(
                '<pre>%s%s [%s] has untrusted %s%s [%s] in %s%s [%s].</pre>',
                message.from.username
                and '@'
                or '',
                message.from.username
                or mattata.escape_html(message.from.first_name),
                message.from.id,
                user.username
                and '@'
                or '',
                user.username
                or mattata.escape_html(user.first_name),
                user.id,
                message.chat.username
                and '@'
                or '',
                message.chat.username
                or mattata.escape_html(message.chat.title),
                message.chat.id
            ),
            'html'
        )
    end
    return mattata.send_message(
        message.chat.id,
        string.format(
            '<pre>%s%s has untrusted %s%s.</pre>',
            message.from.username
            and '@'
            or '',
            message.from.username
            or mattata.escape_html(message.from.first_name),
            user.username
            and '@'
            or '',
            user.username
            or mattata.escape_html(user.first_name)
        ),
        'html'
    )
end

return untrust