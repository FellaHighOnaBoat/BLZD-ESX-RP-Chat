local isOpen = false
local isLoaded = false
local chatHidden = false
local welcomeSent = false

RegisterNUICallback('close', function(data, cb)
    isOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('sendMessage', function(data, cb)
    isOpen = false
    SetNuiFocus(false, false)

    if not data.rawText or data.rawText == '' then
        cb('ok')
        return
    end

    local rawText = data.rawText

    if rawText == '/clear' then
        SendNUIMessage({ action = 'CLEAR' })
        cb('ok')
        return
    end

    if rawText == '/id' then
        local id = GetPlayerServerId(PlayerId())
        SendNUIMessage({
            action = 'ADD_MESSAGE',
            message = {
                text    = 'Your server ID is: **' .. id .. '**',
                type    = 'system',
                channel = 'global',
            }
        })
        cb('ok')
        return
    end

    if rawText:sub(1, 1) == '/' then
        local spaceIdx = rawText:find(' ')
        local command, args

        if spaceIdx then
            command = rawText:sub(2, spaceIdx - 1):lower()
            args    = rawText:sub(spaceIdx + 1)
        else
            command = rawText:sub(2):lower()
            args    = ''
        end

        local knownCommands = {
            me      = true,
            ooc     = true,
            looc    = true,
            dm      = true,
            admin   = true,
        }

        if knownCommands[command] then
            TriggerServerEvent('chat:sendCommand', command, args)
            cb('ok')
            return
        end

        ExecuteCommand(rawText:sub(2))
        cb('ok')
        return
    end

    TriggerServerEvent('chat:sendMessage', data.text, data.channel, rawText)
    cb('ok')
end)

Citizen.CreateThread(function()
    Wait(500)

    SendNUIMessage({
        action = 'INIT',
        config = {
            maxMessages        = Config.MaxMessages,
            fadeTimeout        = Config.FadeTimeout,
            maxInputLength     = Config.MaxInputLength,
            defaultChannel     = Config.DefaultChannel,
            channels           = Config.Channels,
            suggestions        = Config.Suggestions,
            emojis             = Config.Emojis,
            enableSounds       = Config.EnableSounds,
            enableTimestamps   = Config.EnableTimestamps,
            enableEmojis       = Config.EnableEmojis,
            maxVisibleMessages = Config.MaxVisibleMessages,
        }
    })

    isLoaded = true
end)

RegisterCommand('openchat', function()
    if not isLoaded or chatHidden or isOpen then return end
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'OPEN' })
end, false)

RegisterKeyMapping('openchat', 'Open Chat', 'keyboard', 't')

Citizen.CreateThread(function()
    while true do
        Wait(0)
        if isOpen then
            DisableControlAction(0, 245, true)
        end
    end
end)

RegisterNetEvent('chat:receiveMessage')
AddEventHandler('chat:receiveMessage', function(msg)
    SendNUIMessage({
        action  = 'ADD_MESSAGE',
        message = msg,
    })
end)

RegisterNetEvent('chat:addSuggestion')
AddEventHandler('chat:addSuggestion', function(command, description, params)
    SendNUIMessage({
        action     = 'ADD_SUGGESTION',
        suggestion = {
            command     = command,
            description = description or '',
            params      = params or {},
        }
    })
end)

RegisterNetEvent('chat:removeSuggestion')
AddEventHandler('chat:removeSuggestion', function(command)
    SendNUIMessage({
        action  = 'REMOVE_SUGGESTION',
        command = command,
    })
end)

RegisterNetEvent('chat:toggle')
AddEventHandler('chat:toggle', function(visible)
    chatHidden = not visible
    if chatHidden and isOpen then
        isOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'CLOSE' })
    end
end)

RegisterNetEvent('chat:clear')
AddEventHandler('chat:clear', function()
    SendNUIMessage({ action = 'CLEAR' })
end)

AddEventHandler('playerSpawned', function()
    if welcomeSent then return end
    welcomeSent = true
    Wait(3000)
    SendNUIMessage({
        action  = 'ADD_MESSAGE',
        message = {
            text    = 'Welcome to the server! Press **T** to chat.',
            type    = 'system',
            channel = 'global',
        }
    })
end)

function AddChatMessage(msg)
    SendNUIMessage({
        action  = 'ADD_MESSAGE',
        message = msg,
    })
end

exports('addMessage', AddChatMessage)