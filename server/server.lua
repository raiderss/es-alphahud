Framework = nil
Framework = GetFramework()
Citizen.Await(Framework)
Callback = Config.Framework == "ESX" or Config.Framework == "NewESX" and Framework.RegisterServerCallback or Framework.Functions.CreateCallback
local PlayerStress = json.decode(LoadResourceFile(GetCurrentResourceName(), "/Stress.json"))

Citizen.CreateThread(function()
    Citizen.Wait(200) 
    for _, v in pairs(GetPlayers()) do
        local Player
        if Config.Framework == "ESX" or Config.Framework == "NewESX" then
            Player = Framework.GetPlayerFromId
        else
            Player = Framework.Functions.GetPlayer
        end

        local xPlayer = Player(tonumber(v))
        if xPlayer then
            local ID
            if Config.Framework == "ESX" or Config.Framework == "NewESX" then
                ID = xPlayer.identifier
            else
                ID = xPlayer.PlayerData.citizenid
            end
            if ID then
                PlayerStress[ID] = PlayerStress[ID] or 0
                print(json.encode(PlayerStress[ID]))
                TriggerClientEvent('HudPlayerLoad', tonumber(v), PlayerStress[ID])
            end
        else
            print("Player object not found for ID:", v)
        end
    end
    Citizen.Wait(74)  
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(src)
    Wait(700)
    local ID = Framework.GetPlayerFromId(src)?.identifier
    if not PlayerStress[ID] then PlayerStress[ID] = 0 end
    TriggerClientEvent('HudPlayerLoad', src, tonumber(PlayerStress[ID]))
end)

RegisterNetEvent('QBCore:Server:OnPlayerLoaded')
AddEventHandler('QBCore:Server:OnPlayerLoaded', function()
    local source = source
    Wait(700)
    local ID = Framework.Functions.GetPlayer(source)?.PlayerData?.citizenid
    if not PlayerStress[ID] then PlayerStress[ID] = 0 end
    TriggerClientEvent('HudPlayerLoad', source, tonumber(PlayerStress[ID]))
end)


local function SetStressLevel(identifier, newStress)
    newStress = math.min(math.max(newStress, 0), 100)
    if PlayerStress[identifier] ~= newStress then
        PlayerStress[identifier] = newStress
        SaveResourceFile(GetCurrentResourceName(), "./Stress.json", json.encode(PlayerStress), -1)
    end
    return newStress
end

RegisterNetEvent('hud:server:GainStress', function(amount)
    print('gain', amount)
    local src = source
    local Player = (Config.Framework == "ESX" or Config.Framework == "NewESX") and Framework.GetPlayerFromId(source) or Framework.Functions.GetPlayer(source)
    local identifier = (Config.Framework == "ESX" or Config.Framework == "NewESX") and Player.identifier or Player.PlayerData.citizenid
    if IsWhitelisted(src) then
        return
    end
    local newStress = (tonumber(PlayerStress[identifier]) or 0) + amount
    newStress = SetStressLevel(identifier, newStress)
    TriggerClientEvent('hud:client:UpdateStress', src, newStress)
end)

RegisterNetEvent('hud:server:RelieveStress', function(amount)
    print('relieve', amount)
    local src = source
    local Player = (Config.Framework == "ESX" or Config.Framework == "NewESX") and Framework.GetPlayerFromId(source) or Framework.Functions.GetPlayer(source)
    local identifier = (Config.Framework == "ESX" or Config.Framework == "NewESX") and Player.identifier or Player.PlayerData.citizenid
    local newStress = (tonumber(PlayerStress[identifier]) or 0) - amount
    newStress = SetStressLevel(identifier, newStress)
    TriggerClientEvent('hud:client:UpdateStress', src, newStress)
end)


function IsWhitelisted(source)
local player = (Config.Framework == 'ESX' or Config.Framework == 'NewESX') and Framework.GetPlayerFromId(source) or Framework.Functions.GetPlayer(source)
if player then
    local jobName = (Config.Framework == 'ESX' or Config.Framework == 'NewESX') and player.job.name or player.PlayerData.job.name
    for _, v in pairs(Config.Stress.DisableJobs) do
        if jobName == v then
            return true
        end
    end
end
return false
end

function GetIdentifier(source)
if Config.Framework == "ESX" or Config.Framework == "NewESX" then
    local xPlayer = Framework.GetPlayerFromId(tonumber(source))
    return xPlayer and xPlayer.getIdentifier() or "0"
else
    local Player = Framework.Functions.GetPlayer(tonumber(source))
    return Player and Player.PlayerData.citizenid or "0"
end
end