NitroVeh = {}


Citizen.CreateThread(function()
    Citizen.Wait(3500)
    while Framework == nil do Citizen.Wait(72) end
    UsableItem = (Config.Framework == "ESX" or Config.Framework == "NewESX") and Framework.RegisterUsableItem or Framework.Functions.CreateUseableItem
    UsableItem(Config.NitroItem, function(source)
        TriggerClientEvent('SetupNitro', source)
    end)
end)

RegisterServerEvent('RemoveNitroItem')
AddEventHandler('RemoveNitroItem', function(Plate)
    if (Config.Framework == "ESX" or Config.Framework == "NewESX") then
        Framework.GetPlayerFromId(source).removeInventoryItem(Config.NitroItem, 1)
    else
        Framework.Functions.GetPlayer(source).Functions.RemoveItem(Config.NitroItem, 1)
    end
    print("RemoveNitroItem",Plate)
    if Plate then
        NitroVeh[Plate] = 100
        TriggerClientEvent('UpdateData', -1, NitroVeh)
    end
end)

RegisterServerEvent('UpdateNitro')
AddEventHandler('UpdateNitro', function(Plate, Get)
    if Plate then
        if NitroVeh[Plate] then
            NitroVeh[Plate] = Get
            TriggerClientEvent('UpdateData', -1, NitroVeh)
        end
    end
end)
