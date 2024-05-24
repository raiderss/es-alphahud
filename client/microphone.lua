function setMicrophoneSettings(type, value)
    SendNUIMessage({ data = "SOUND", type = type, value = value })
end
local micIsOn = true
local firstCheck = true
function registerEvent(eventName, handler)
    RegisterNetEvent(eventName)
    AddEventHandler(eventName, handler)
end
if Config.Voice == 'mumble' or Config.Voice == 'pma' then
    registerEvent('pma-voice:setTalkingMode', function(voiceMode)
        setMicrophoneSettings('mic_level', voiceMode)
    end)
    registerEvent("mumble:SetVoiceData", function(player, key, value)
        local playerPed = PlayerPedId() 
        if GetPlayerServerId(NetworkGetEntityOwner(playerPed)) == player and key == 'mode' then
            setMicrophoneSettings('mic_level', value)
        end
    end)
    CreateThread(function()
        local isTalking = false
        while true do
            isTalking = NetworkIsPlayerTalking(PlayerId())
            setMicrophoneSettings('isTalking', isTalking)
            Wait(800)
        end
    end)
    CreateThread(function()
        while true do
            local isConnected = MumbleIsConnected()
            if isConnected ~= micIsOn or firstCheck then
                micIsOn = isConnected
                firstCheck = false
                setMicrophoneSettings('isMuted', not isConnected)
            end
            Wait(2000)
        end
    end)
else
    registerEvent('SaltyChat_VoiceRangeChanged', function(voiceRange, index)
        setMicrophoneSettings('mic_level', index + 1)
    end)

    registerEvent('SaltyChat_TalkStateChanged', function(isTalking)
        setMicrophoneSettings('isTalking', isTalking)
    end)

    registerEvent('SaltyChat_PluginStateChanged', function(state)
        setMicrophoneSettings('isMuted', state == 0 or state == -1)
    end)

    registerEvent('SaltyChat_MicStateChanged', function(isMicrophoneMuted)
        setMicrophoneSettings('isMuted', isMicrophoneMuted)
    end)
end
