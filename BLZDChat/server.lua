ESX = exports["es_extended"]:getSharedObject()

local playerRoles = {}

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if GetResourceState('chat') == 'started' then
        StopResource('chat')
    end
end)

function GetPlayers()
    local players = {}
    for i = 0, GetNumPlayerIndices() - 1 do
        local pid = tonumber(GetPlayerFromIndex(i))
        if pid then
            table.insert(players, pid)
        end
    end
    return players
end

function SplitString(str, sep)
    local parts = {}
    for part in str:gmatch('([^' .. sep .. ']+)') do
        table.insert(parts, part)
    end
    return parts
end

function table.shallow_copy(t)
    local copy = {}
    for k, v in pairs(t) do copy[k] = v end
    return copy
end

function GetPlayerRole(source)
    if playerRoles[source] then return playerRoles[source] end
    if IsPlayerAceAllowed(source, 'chat.admin') then return 'admin' end
    return 'citizen'
end

function SetPlayerRole(source, role)
    playerRoles[source] = role
end
exports('setPlayerRole', SetPlayerRole)

function GetRoleConfig(role)
    return Config.Roles[role] or Config.Roles['citizen'] or { label = 'PLAYER', color = '#6B7280', priority = 0 }
end

function GetChannelConfig(channelId)
    for _, ch in ipairs(Config.Channels) do
        if ch.id == channelId then return ch end
    end
    return Config.Channels[1]
end

function IsAdmin(source)
    if IsPlayerAceAllowed(source, 'chat.admin') then return true end
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        local group = xPlayer.getGroup()
        if group == 'admin' or group == 'superadmin' or group == 'mod' then return true end
    end
    return false
end

function BuildBaseMessage(source, channel)
    local playerName  = GetPlayerName(source)
    local role        = GetPlayerRole(source)
    local roleConfig  = GetRoleConfig(role)
    local channelConfig = GetChannelConfig(channel)

    return {
        author       = playerName,
        text         = '',
        channel      = channel,
        type         = 'normal',
        role         = role,
        roleLabel    = roleConfig.label,
        roleColor    = roleConfig.color,
        channelColor = channelConfig.color,
        channelLabel = channelConfig.label,
        color        = roleConfig.color,
        id           = source,
    }
end

function SendError(source, text)
    TriggerClientEvent('chat:receiveMessage', source, {
        text    = text,
        type    = 'error',
        channel = 'global',
    })
end

RegisterNetEvent('chat:sendCommand')
AddEventHandler('chat:sendCommand', function(command, args)
    local source     = source
    local playerName = GetPlayerName(source)
    if not playerName then return end

    if command == 'me' then
        if not args or args == '' then
            SendError(source, 'Usage: /me [action]')
            return
        end

        local msg      = BuildBaseMessage(source, 'me')
        msg.text       = ('**%s** %s'):format(playerName, args)
        msg.type       = 'action'
        msg.roleLabel  = 'ME'
        msg.roleColor  = '#10B981'
        msg.channelLabel = 'Me'
        msg.channelColor = '#10B981'

        local ped    = GetPlayerPed(source)
        local coords = GetEntityCoords(ped)

        for _, pid in ipairs(GetPlayers()) do
            local tPed    = GetPlayerPed(pid)
            local tCoords = GetEntityCoords(tPed)
            if #(coords - tCoords) <= Config.LocalChatRange then
                TriggerClientEvent('chat:receiveMessage', pid, msg)
            end
        end
        print(('[CHAT][ME] %s: %s'):format(playerName, args))

    elseif command == 'ooc' then
        if not args or args == '' then
            SendError(source, 'Usage: /ooc [message]')
            return
        end

        local msg        = BuildBaseMessage(source, 'ooc')
        msg.text         = args
        msg.type         = 'ooc'
        msg.author       = ('[OOC] %s (ID: %d)'):format(playerName, source)
        msg.roleLabel    = 'OOC'
        msg.roleColor    = '#6B7280'
        msg.channelLabel = 'OOC'
        msg.channelColor = '#6B7280'

        TriggerClientEvent('chat:receiveMessage', -1, msg)
        print(('[CHAT][OOC] %s: %s'):format(playerName, args))

    elseif command == 'looc' then
        if not args or args == '' then
            SendError(source, 'Usage: /looc [message]')
            return
        end

        local msg        = BuildBaseMessage(source, 'ooclocal')
        msg.text         = args
        msg.type         = 'ooc'
        msg.author       = ('[LOOC] %s (ID: %d)'):format(playerName, source)
        msg.roleLabel    = 'LOOC'
        msg.roleColor    = '#78716C'
        msg.channelLabel = 'OOC Local'
        msg.channelColor = '#78716C'

        local ped    = GetPlayerPed(source)
        local coords = GetEntityCoords(ped)

        for _, pid in ipairs(GetPlayers()) do
            local tPed    = GetPlayerPed(pid)
            local tCoords = GetEntityCoords(tPed)
            if #(coords - tCoords) <= Config.LocalChatRange then
                TriggerClientEvent('chat:receiveMessage', pid, msg)
            end
        end
        print(('[CHAT][LOOC] %s: %s'):format(playerName, args))

    elseif command == 'dm' then
        local parts    = SplitString(args, ' ')
        local targetId = tonumber(parts[1])

        if not targetId or not GetPlayerName(targetId) then
            SendError(source, 'Usage: /dm [id] [message]')
            return
        end

        local dmText = table.concat(parts, ' ', 2)
        if not dmText or dmText == '' then
            SendError(source, 'Usage: /dm [id] [message]')
            return
        end

        local targetName = GetPlayerName(targetId)

        local baseMsg = {
            channel      = 'dm',
            type         = 'dm',
            roleLabel    = 'DM',
            roleColor    = '#10B981',
            channelColor = '#10B981',
            channelLabel = 'DM',
            color        = '#10B981',
            text         = dmText,
        }

        local toTarget       = table.shallow_copy(baseMsg)
        toTarget.author      = ('From %s (ID: %d)'):format(playerName, source)
        toTarget.id          = source

        local toSender       = table.shallow_copy(baseMsg)
        toSender.author      = ('To %s (ID: %d)'):format(targetName, targetId)
        toSender.id          = source

        TriggerClientEvent('chat:receiveMessage', targetId, toTarget)
        TriggerClientEvent('chat:receiveMessage', source, toSender)
        print(('[CHAT][DM] %s -> %s: %s'):format(playerName, targetName, dmText))

    elseif command == 'admin' then
        if not IsAdmin(source) then
            SendError(source, 'You do not have permission to use admin chat.')
            return
        end

        if not args or args == '' then
            SendError(source, 'Usage: /admin [message]')
            return
        end

        local msg        = BuildBaseMessage(source, 'admin')
        msg.text         = args
        msg.type         = 'admin'
        msg.roleLabel    = 'ADMIN'
        msg.roleColor    = '#EF4444'
        msg.channelLabel = 'Admin'
        msg.channelColor = '#EF4444'

        for _, pid in ipairs(GetPlayers()) do
            if IsAdmin(pid) then
                TriggerClientEvent('chat:receiveMessage', pid, msg)
            end
        end
        print(('[CHAT][ADMIN] %s: %s'):format(playerName, args))
    end
end)

RegisterNetEvent('chat:sendMessage')
AddEventHandler('chat:sendMessage', function(text, channel, rawText)
    local source     = source
    local playerName = GetPlayerName(source)

    if not text or text == '' then return end
    if not playerName then return end

    text    = text:sub(1, Config.MaxInputLength)
    channel = channel or Config.DefaultChannel

    local channelConfig = GetChannelConfig(channel)
    if channelConfig.adminOnly and not IsAdmin(source) then
        SendError(source, 'You do not have permission to use that channel.')
        return
    end

    local msg  = BuildBaseMessage(source, channel)
    msg.text   = text

    if channel == 'local' then
        local ped    = GetPlayerPed(source)
        local coords = GetEntityCoords(ped)

        for _, pid in ipairs(GetPlayers()) do
            local tPed    = GetPlayerPed(pid)
            local tCoords = GetEntityCoords(tPed)
            if #(coords - tCoords) <= Config.LocalChatRange then
                TriggerClientEvent('chat:receiveMessage', pid, msg)
            end
        end
        print(('[CHAT][LOCAL] %s: %s'):format(playerName, text))
        return
    end

    if channel == 'admin' then
        if not IsAdmin(source) then
            SendError(source, 'You do not have permission to use admin chat.')
            return
        end
        msg.type      = 'admin'
        msg.roleLabel = 'ADMIN'
        msg.roleColor = '#EF4444'

        for _, pid in ipairs(GetPlayers()) do
            if IsAdmin(pid) then
                TriggerClientEvent('chat:receiveMessage', pid, msg)
            end
        end
        print(('[CHAT][ADMIN] %s: %s'):format(playerName, text))
        return
    end

    if channel == 'ooc' then
        msg.type   = 'ooc'
        msg.author = ('[OOC] %s (ID: %d)'):format(playerName, source)
    elseif channel == 'ooclocal' then
        msg.type   = 'ooc'
        msg.author = ('[LOOC] %s (ID: %d)'):format(playerName, source)

        local ped    = GetPlayerPed(source)
        local coords = GetEntityCoords(ped)

        for _, pid in ipairs(GetPlayers()) do
            local tPed    = GetPlayerPed(pid)
            local tCoords = GetEntityCoords(tPed)
            if #(coords - tCoords) <= Config.LocalChatRange then
                TriggerClientEvent('chat:receiveMessage', pid, msg)
            end
        end
        print(('[CHAT][LOOC] %s: %s'):format(playerName, text))
        return
    elseif channel == 'me' then
        msg.type   = 'action'
        msg.text   = ('**%s** %s'):format(playerName, text)

        local ped    = GetPlayerPed(source)
        local coords = GetEntityCoords(ped)

        for _, pid in ipairs(GetPlayers()) do
            local tPed    = GetPlayerPed(pid)
            local tCoords = GetEntityCoords(tPed)
            if #(coords - tCoords) <= Config.LocalChatRange then
                TriggerClientEvent('chat:receiveMessage', pid, msg)
            end
        end
        print(('[CHAT][ME] %s: %s'):format(playerName, text))
        return
    end

    TriggerClientEvent('chat:receiveMessage', -1, msg)
    print(('[CHAT][%s] %s: %s'):format(string.upper(channel), playerName, text))
end)

RegisterCommand('announce', function(source, args, rawCommand)
    if source > 0 and not IsAdmin(source) then return end
    local text = table.concat(args, ' ')
    if text == '' then return end

    TriggerClientEvent('chat:receiveMessage', -1, {
        author       = '📢 SERVER',
        text         = text,
        type         = 'system',
        channel      = 'global',
        color        = '#8B5CF6',
        roleLabel    = 'ANNOUNCE',
        roleColor    = '#8B5CF6',
        channelLabel = 'Global',
        channelColor = '#8B5CF6',
    })
end, true)

RegisterCommand('clearchat', function(source, args, rawCommand)
    if source > 0 and not IsAdmin(source) then return end
    TriggerClientEvent('chat:clear', -1)
end, true)

AddEventHandler('playerJoining', function()
    local source = source
    local name   = GetPlayerName(source)
    Wait(2000)
    TriggerClientEvent('chat:receiveMessage', -1, {
        text    = ('**%s** has joined the server.'):format(name),
        type    = 'success',
        channel = 'global',
    })
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    local name   = GetPlayerName(source)
    playerRoles[source] = nil
    TriggerClientEvent('chat:receiveMessage', -1, {
        text    = ('**%s** has left the server. (%s)'):format(name or 'Unknown', reason or 'Unknown'),
        type    = 'error',
        channel = 'global',
    })
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    local job = xPlayer.job.name
    if job == 'police' then
        SetPlayerRole(playerId, 'police')
    elseif job == 'ambulance' then
        SetPlayerRole(playerId, 'ambulance')
    elseif job == 'mechanic' then
        SetPlayerRole(playerId, 'mechanic')
    end
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(playerId, job)
    if job.name == 'police' then
        SetPlayerRole(playerId, 'police')
    elseif job.name == 'ambulance' then
        SetPlayerRole(playerId, 'ambulance')
    elseif job.name == 'mechanic' then
        SetPlayerRole(playerId, 'mechanic')
    else
        SetPlayerRole(playerId, 'citizen')
    end
end)

exports('sendGlobalMessage', function(text, msgType)
    TriggerClientEvent('chat:receiveMessage', -1, {
        text    = text,
        type    = msgType or 'system',
        channel = 'global',
    })
end)

exports('sendPlayerMessage', function(target, text, msgType)
    TriggerClientEvent('chat:receiveMessage', target, {
        text    = text,
        type    = msgType or 'system',
        channel = 'global',
    })
end)

exports('sendMessageToPlayer', function(target, text, msgType, channel)
    TriggerClientEvent('chat:receiveMessage', target, {
        text    = text,
        type    = msgType or 'system',
        channel = channel or 'global',
    })
end)

-- PREVIEW ONLY

RegisterCommand('preview', function(source, args, rawCommand)
    if source > 0 and not IsAdmin(source) then return end

    local playerName = GetPlayerName(source)
    local role       = GetPlayerRole(source)
    local roleConfig = GetRoleConfig(role)

    Wait(200)
    TriggerClientEvent('chat:receiveMessage', source, {
        author       = '📢 SERVER',
        text         = 'Server announcement preview — welcome to the server!',
        type         = 'system',
        channel      = 'global',
        color        = '#8B5CF6',
        roleLabel    = 'ANNOUNCE',
        roleColor    = '#8B5CF6',
        channelLabel = 'Global',
        channelColor = '#8B5CF6',
    })

    Wait(200)
    TriggerClientEvent('chat:receiveMessage', source, {
        author       = playerName,
        text         = 'Hey everyone, this is a global chat message!',
        type         = 'normal',
        channel      = 'global',
        role         = role,
        roleLabel    = roleConfig.label,
        roleColor    = roleConfig.color,
        channelLabel = 'Global',
        channelColor = '#8B5CF6',
        color        = roleConfig.color,
        id           = source,
    })

    Wait(200)
    TriggerClientEvent('chat:receiveMessage', source, {
        author       = playerName,
        text         = 'This is a local chat message, only nearby players see this.',
        type         = 'normal',
        channel      = 'local',
        role         = role,
        roleLabel    = roleConfig.label,
        roleColor    = roleConfig.color,
        channelLabel = 'Local',
        channelColor = '#F59E0B',
        color        = roleConfig.color,
        id           = source,
    })

    Wait(200)
    TriggerClientEvent('chat:receiveMessage', source, {
        author       = ('[OOC] %s (ID: %d)'):format(playerName, source),
        text         = 'This is an OOC global message, visible to the whole server.',
        type         = 'ooc',
        channel      = 'ooc',
        roleLabel    = 'OOC',
        roleColor    = '#6B7280',
        channelLabel = 'OOC',
        channelColor = '#6B7280',
        color        = '#6B7280',
        id           = source,
    })

    Wait(200)
    TriggerClientEvent('chat:receiveMessage', source, {
        author       = ('[LOOC] %s (ID: %d)'):format(playerName, source),
        text         = 'This is a local OOC, only people nearby can read this.',
        type         = 'ooc',
        channel      = 'ooclocal',
        roleLabel    = 'LOOC',
        roleColor    = '#78716C',
        channelLabel = 'OOC Local',
        channelColor = '#78716C',
        color        = '#78716C',
        id           = source,
    })

    Wait(200)
    TriggerClientEvent('chat:receiveMessage', source, {
        author       = playerName,
        text         = ('**%s** pulls out a notepad and begins writing something down.'):format(playerName),
        type         = 'action',
        channel      = 'me',
        role         = role,
        roleLabel    = 'ME',
        roleColor    = '#10B981',
        channelLabel = 'Me',
        channelColor = '#10B981',
        color        = '#10B981',
        id           = source,
    })

    Wait(200)
    TriggerClientEvent('chat:receiveMessage', source, {
        author       = ('From %s (ID: %d)'):format(playerName, source),
        text         = 'Hey, this is a private direct message between two players.',
        type         = 'dm',
        channel      = 'dm',
        roleLabel    = 'DM',
        roleColor    = '#10B981',
        channelLabel = 'DM',
        channelColor = '#10B981',
        color        = '#10B981',
        id           = source,
    })

    Wait(200)
    TriggerClientEvent('chat:receiveMessage', source, {
        author       = playerName,
        text         = 'This is an admin-only chat message.',
        type         = 'admin',
        channel      = 'admin',
        roleLabel    = 'ADMIN',
        roleColor    = '#EF4444',
        channelLabel = 'Admin',
        channelColor = '#EF4444',
        color        = '#EF4444',
        id           = source,
    })

    Wait(200)
    TriggerClientEvent('chat:receiveMessage', source, {
        author       = 'Officer Smith',
        text         = 'Suspect heading northbound on the freeway, requesting backup.',
        type         = 'normal',
        channel      = 'global',
        role         = 'police',
        roleLabel    = 'LSPD',
        roleColor    = '#3B82F6',
        channelLabel = 'Global',
        channelColor = '#8B5CF6',
        color        = '#3B82F6',
        id           = source,
    })

    Wait(200)
    TriggerClientEvent('chat:receiveMessage', source, {
        author       = 'Paramedic Jones',
        text         = 'Unit en route to the hospital with one critical patient.',
        type         = 'normal',
        channel      = 'global',
        role         = 'ambulance',
        roleLabel    = 'EMS',
        roleColor    = '#EC4899',
        channelLabel = 'Global',
        channelColor = '#8B5CF6',
        color        = '#EC4899',
        id           = source,
    })

    Wait(200)
    TriggerClientEvent('chat:receiveMessage', source, {
        author       = 'Mike the Mechanic',
        text         = 'Shop is open, bring your vehicle in for repairs!',
        type         = 'normal',
        channel      = 'global',
        role         = 'mechanic',
        roleLabel    = 'MECH',
        roleColor    = '#F97316',
        channelLabel = 'Global',
        channelColor = '#8B5CF6',
        color        = '#F97316',
        id           = source,
    })

    Wait(200)
    TriggerClientEvent('chat:receiveMessage', source, {
        text    = 'Preview complete — all message types shown above.',
        type    = 'system',
        channel = 'global',
    })
end, true)