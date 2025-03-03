local speedBuffer, velBuffer, pauseActive, isCarHud, stress, speedMultiplier, PlayerData, SpeedType, PlayerData = {0.0,0.0}, {}, false, false, 0, nil, nil, nil
Display = nil
PlayerLoaded = nil
Loaded = nil
PlayerPed = nil
Framework = nil
Framework = GetFramework()
Citizen.CreateThread(function()
   while Framework == nil do Citizen.Wait(750) end
   Citizen.Wait(2500)
end)
Callback = Config.Framework == "ESX" or Config.Framework == "NewESX" and Framework.TriggerServerCallback or Framework.Functions.TriggerCallback

function updateStatus(statusName, value)
    if statusName == 'hunger' then
        SendNUIMessage({
            data = "STATUS",
            hunger = math.ceil(value / 10000),
            thirst = math.ceil(GetStatusValue('thirst') / 10000)
        })
    elseif statusName == 'thirst' then
        SendNUIMessage({
            data = "STATUS",
            hunger = math.ceil(GetStatusValue('hunger') / 10000),
            thirst = math.ceil(value / 10000)
        })
    end
end

function GetStatusValue(statusName)
    local value = 0
    TriggerEvent('esx_status:getStatus', statusName, function(status)
        if status then
            value = status.val
        end
    end)
    return value
end

function Evaluate()
    return Config.Framework ~= nil and PlayerLoaded and PlayerPed ~= nil
end

Citizen.CreateThread(function()
    while true do
        PlayerPed = PlayerPedId()
        Citizen.Wait(4500)
    end
end)

local hudComponents = {6, 7, 8, 9, 3, 4}

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        for _, component in ipairs(hudComponents) do
            HideHudComponentThisFrame(component)
        end
    end
end)


exports('eyestore', function(state)
    SendNUIMessage({ data = 'EXIT', args = state })
end)

RegisterCommand("stress", function(source, args, rawCommand)
    local item = args[1] 
    local value = tonumber(args[2]) 
    if item ~= "add" and item ~= "remove" then
        print("Invalid command, use: stress add [value] or stress remove [value]")
        return
    end
    if not value then
        print("Please specify a valid number for value.")
        return
    end
    local eventName = item == 'remove' and 'hud:server:RelieveStress' or 'hud:server:GainStress'
    TriggerServerEvent(eventName, value)
    print(item == "add" and ("Adding " .. value .. " stress.") or ("Removing " .. value .. " stress."))
end, false)
TriggerEvent('chat:addSuggestion', '/stress', 'Modifies stress level', {
    { name="action", help="add or remove" },
    { name="value", help="amount of stress to modify" }
})

exports('stress', function(item, val)
    local eventName = item == 'remove' and 'hud:server:RelieveStress' or 'hud:server:GainStress'
    TriggerServerEvent(eventName, val)
end)

-- ! Stamina
Citizen.CreateThread(function()
    local wait, LastOxygen
    while true do
        local playerPed = PlayerPedId()
        local newOxygen = GetPlayerSprintStaminaRemaining(PlayerId())
        local inVehicle = IsPedInAnyVehicle(playerPed)
        local inWater = IsEntityInWater(playerPed)
        local oxygen
        if inVehicle then
            wait = 2100
        else
            if LastOxygen ~= newOxygen then
                wait = 125
                oxygen = inWater and GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10 or 100 - newOxygen
                LastOxygen = newOxygen
                SendNUIMessage({data = 'OXYGEN', math.ceil(oxygen)})
            else
                wait = 1850
            end
        end
        Citizen.Wait(wait)
    end
end)

local parachuteTintIndex = 6
local waitTime = 1700

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(waitTime)
        local playerPed = PlayerPedId()
        local parachuteState = GetPedParachuteState(playerPed)
        local inAirVehicle = IsPedInAnyHeli(playerPed) or IsPedInAnyPlane(playerPed)
        if parachuteState >= 0 or inAirVehicle then
            SetPlayerParachutePackTintIndex(playerPed, parachuteTintIndex)
            local heightAboveGround = math.floor(GetEntityHeightAboveGround(playerPed))
            SendNUIMessage({ data = "PARACHUTE", value = heightAboveGround })
            SendNUIMessage({ data = "PARACHUTE_SET", value = true })
        else
            SendNUIMessage({ data = "PARACHUTE_SET", value = false })
        end
    end
end)



RegisterNetEvent('HudPlayerLoad', function(eyes)
    Citizen.Wait(tonumber(200))  
    local frameworkType = Config.Framework
    local playerDataFunc = (frameworkType == "ESX" or frameworkType == "NewESX")
        and Framework.GetPlayerData or Framework.Functions.GetPlayerData
    PlayerData = playerDataFunc()  
    stress = Config.Stress.Enabled and eyes or 0
    SendNUIMessage({data = "STRESS", stress = stress})
    if frameworkType == 'QBCore' or frameworkType == 'OLDQBCore' then 
        local metadata = PlayerData.metadata
        SendNUIMessage({
            data = "STATUS",
            hunger = math.ceil(metadata["hunger"]),
            thirst = math.ceil(metadata["thirst"])
        })
    elseif frameworkType == "ESX" or frameworkType == "NewESX" then
        TriggerEvent('esx_status:getStatus', 'hunger', function(status) 
            if status then
                updateStatus('hunger', status.val)
            end
        end)

        TriggerEvent('esx_status:getStatus', 'thirst', function(status) 
            if status then
                updateStatus('thirst', status.val)
            end
        end)
    end

    Callback('EYES', function(data) 
        SendNUIMessage({data = "PLAYER", player = data})
    end) 
      
    PlayerLoaded = true
end)

RegisterNetEvent("esx_status:onTick")
AddEventHandler("esx_status:onTick", function(data)
    if data then
        for _, v in pairs(data) do
            if v and v.name and v.val then
                updateStatus(v.name, v.val)
            end
        end
    end
end)


-- ? Status
RegisterNetEvent('hud:client:UpdateNeeds', function(newHunger, newThirst) -- Triggered in qb-core
    local Hungerr = 0
    local Thirstt = 0
    if math.ceil(newHunger) > 100 then
        Hungerr = 100
    else
        Hungerr = math.ceil(newHunger)
    end
    if math.ceil(newThirst) > 100 then
        Thirstt = 100
    else
        Thirstt = math.ceil(newThirst)
    end
    SendNUIMessage({data = "STATUS", hunger = Hungerr, thirst = Thirstt})
end)

Citizen.CreateThread(function()
    Citizen.Wait(100)
    local defaultAspectRatio = 1920/1080 
    local resolutionX, resolutionY = GetActiveScreenResolution()
    local aspectRatio = resolutionX/resolutionY
    local minimapOffset = 0
    if aspectRatio > defaultAspectRatio then
        minimapOffset = ((defaultAspectRatio-aspectRatio)/3.6)-0.008
    end
    RequestStreamedTextureDict("squaremap", false)
    while not HasStreamedTextureDictLoaded("squaremap") do
        Wait(150)
    end
    SetMinimapClipType(0)
    AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "squaremap", "radarmasksm")
    AddReplaceTexture("platform:/textures/graphics", "radarmask1g", "squaremap", "radarmasksm")
    SetMinimapComponentPosition("minimap", "L", "B", 0.0 + minimapOffset, -0.05, 0.1638, 0.183) 
    SetMinimapComponentPosition("minimap_mask", "L", "B", 0.0 + minimapOffset, 0.03, 0.128, 0.20) 
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0 + minimapOffset, 0.015, 0.245, 0.300) 
    SetBlipAlpha(GetNorthRadarBlip(), 0)
    SetRadarBigmapEnabled(true, false)
    SetMinimapClipType(0)
    Wait(0)
    SetRadarBigmapEnabled(false, false)
end)


RegisterNetEvent('seatbelt:client:ToggleSeatbelt', function() -- Triggered in smallresources
    seatbeltOn = not seatbeltOn
end)

exports("SeatbeltState", function(state)
    seatbeltOn = state
end)

RegisterKeyMapping('seatbelt', 'Toggle Seatbelt', 'keyboard', Config.SeatbeltControl)

local function Fwv(entity)
    local hr = GetEntityHeading(entity) + 90.0
    if hr < 0.0 then hr = 360.0 + hr end
    hr = hr * 0.0174533
    return { x = math.cos(hr) * 2.0, y = math.sin(hr) * 2.0 }
end

local function playSound(soundName)
    TriggerServerEvent("InteractSound_SV:PlayOnSource", seatbeltOn and "carbuckle" or "carunbuckle", 0.25)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)
        local resourceState = GetResourceState('qb-smallresources')
        if resourceState == "started" then
            return 
        end
        RegisterCommand("seatbelt", function()
            if IsPedInAnyVehicle(playerPed, false) then
                seatbeltOn = not seatbeltOn
                if seatbeltOn then
                    TriggerEvent("notification", "Seatbelt buckled", 1)
                    playSound("buckle")
                else
                    TriggerEvent("notification", "Seatbelt removed", 2)
                    playSound("unbuckle")
                end
            end
        end, false)

        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(0)
                local vehicle = GetVehiclePedIsIn(playerPed, false)
                if vehicle ~= 0 then
                    if seatbeltOn then
                        DisableControlAction(0, 75, true) 
                        local currentSpeed = GetEntitySpeed(vehicle)
                        local currentVector = GetEntityVelocity(vehicle)
                        if currentSpeed > 15.0 and math.abs(currentVector.y) > 1.0 then
                            local fw = Fwv(playerPed)
                            local co = GetEntityCoords(playerPed)
                            SetEntityCoords(playerPed, co.x + fw.x, co.y + fw.y, co.z - 0.47, true, true, true)
                            SetEntityVelocity(playerPed, currentVector.x, currentVector.y, currentVector.z)
                            Wait(500)
                            SetPedToRagdoll(playerPed, 1000, 1000, 0, 0, 0, 0)
                            seatbeltOn = false
                        end
                    end
                else
                    Citizen.Wait(1000)
                end
            end
        end)
        break 
    end
end)

local LastStreet1, LastStreet2
    Citizen.CreateThread(function()
        local wait = 2500
        while true do
        local Coords = GetEntityCoords(PlayerPed)
        local Street1, Street2 = GetStreetNameAtCoord(Coords.x, Coords.y, Coords.z, Citizen.ResultAsInteger(), Citizen.ResultAsInteger())
        if IsPedInAnyVehicle(PlayerPed) then
            wait = 1700
        else
            wait = 4000
        end
        local StreetName1 = GetLabelText(GetNameOfZone(Coords.x, Coords.y, Coords.z))
        local StreetName2 = GetStreetNameFromHashKey(Street1)
        if (Street1 ~= LastStreet1 or Street2 ~= LastStreet2) then
            SendNUIMessage({ data = "STREET", street1 = StreetName1, street2 = StreetName2 })
            LastStreet1 = StreetName1
            LastStreet2 = StreetName2
        elseif not shouldSendData then
            LastStreet1 = false
            LastStreet2 = false
        end
        Citizen.Wait(wait)
    end
end)

-- ! Health
local LastHealth
Citizen.CreateThread(function()
    local wait
    while true do
        if Evaluate() then
            local Health = math.floor((GetEntityHealth(PlayerPed)/2))
            if IsPedInAnyVehicle(PlayerPed) then wait = 250 else wait = 650 end
            if Health ~= LastHealth then
                if GetEntityModel(PlayerPed) == `mp_f_freemode_01` and Health ~= 0 then Health = (Health+13) end
                SendNUIMessage({data = 'HEALTH', Health})
                LastHealth = Health
            else
                wait = wait + 1200
            end
        else
            Citizen.Wait(2000)
        end
        Citizen.Wait(wait)
    end
end)

-- ! Armour
local function updateArmor()
    local Armour = GetPedArmour(PlayerPed)
    SendNUIMessage({data = 'ARMOR', Armour})
  end
  
  Citizen.CreateThread(function()
    while true do
      updateArmor()
      Citizen.Wait(2500)
    end
  end)

local doorsLocked = false 
RegisterKeyMapping('lockdoors', 'Vehicle Door', 'keyboard', Config.LockedControl)
local function toggleVehicleDoors(playerPed, vehicle)
    if doorsLocked then
        SetVehicleDoorsLocked(vehicle, 1)  
        TriggerEvent("notification", "Vehicle doors unlocked", 1)
        TriggerServerEvent("InteractSound_SV:PlayOnSource", 'unlock', 0.5)
    else
        SetVehicleDoorsLocked(vehicle, 2)  
        TriggerEvent("notification", "Vehicle doors locked", 2)
        TriggerServerEvent("InteractScaleform_SV:PlayOnSource", 'lock', 0.5)
    end
    doorsLocked = not doorsLocked
end
RegisterCommand("lockdoors", function()
    local playerPed = PlayerPedId() 
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == playerPed then
        toggleVehicleDoors(playerPed, vehicle)
    end
end, false)
Citizen.CreateThread(function()
    local playerPed = PlayerPedId() 
    while true do
        Citizen.Wait(0)
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == playerDraftPed then
            if doorsLocked then
                DisableControlAction(0, 75, true) 
            end
        else
            Citizen.Wait(1000)
        end
    end
end)


local LastData = {
    Speed = 0,
    Rpm = 0,
    Fuel = 0,
    Tool = false,
    Light = false,
    seatbeltOn = false,
    cruiseOn = false,
    doorsLocked = false,
    Signal = false,
    Gear = 0,
}

----------------------------------------------------------------------------------

Citizen.CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if IsPedInVehicle(ped, vehicle, false) then
            local Percentage = (Config.speedMultiplier == 'KM/H') and 3.6 or 2.23694
            local Speed = math.floor(GetEntitySpeed(vehicle) * Percentage)
            local RawRpm = GetVehicleCurrentRpm(vehicle)
            local Fuel = getFuelLevel(vehicle)
            local Tool = GetVehicleBodyHealth(vehicle) / 10
            local Seatbelt = seatbeltOn
            local Gear = GetVehicleCurrentGear(vehicle)
            local Cruise = cruiseOn
            local Doors = doorsLocked
            local _, LightLights, LightHighlights = GetVehicleLightsState(vehicle)
            local Light = LightLights == 1 or LightHighlights == 1
            local Signal = GetVehicleIndicatorLights(vehicle)
            local Rpm = math.floor(RawRpm * 200)
            Rpm = (Rpm == 40) and 0 or Rpm
            DisplayRadar(true)
            if LastData.Speed ~= Speed or LastData.Gear ~= Gear or LastData.Rpm ~= Rpm or LastData.Fuel ~= Fuel or 
               LastData.Tool ~= Tool or LastData.Light ~= Light or LastData.seatbeltOn ~= Seatbelt or 
               LastData.cruiseOn ~= Cruise or LastData.doorsLocked ~= Doors or LastData.Signal ~= Signal then
                SendNUIMessage({
                    data = 'CAR',
                    speed = Speed,
                    rpm = Rpm,
                    fuel = Fuel,
                    gear = Gear,
                    tool = Tool,
                    state = Light,
                    seatbelt = Seatbelt,
                    brakes = Cruise,
                    door = Doors,
                    signal = Signal
                })
                LastData.Speed = Speed
                LastData.Rpm = Rpm
                LastData.Fuel = Fuel
                LastData.Tool = Tool
                LastData.Light = Light
                LastData.seatbeltOn = Seatbelt
                LastData.Gear = Gear
                LastData.cruiseOn = Cruise
                LastData.doorsLocked = Doors
                LastData.Signal = Signal
            end
            Citizen.Wait(100) 
        else
            SendNUIMessage({ data = 'CIVIL' })
            SetRadarBigmapEnabled(false, false)
            SetRadarZoom(1000)
            DisplayRadar(false)
            Citizen.Wait(1000) 
        end
    end
end)

local lastFuelUpdate = 0
function getFuelLevel(vehicle)
    local updateTick = GetGameTimer()
    if (updateTick - lastFuelUpdate) > 2000 then
        lastFuelUpdate = updateTick
        LastFuel = math.floor(Config.GetVehFuel(vehicle))
    end
    return LastFuel
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(650)
        local isMenuActive = IsPauseMenuActive()
        if isMenuActive ~= pauseActive then
            exports[GetCurrentResourceName()]:eyestore(not isMenuActive)
            pauseActive = isMenuActive
        end
    end
end)


local playerPed = nil
local function updatePlayerPed()
  playerPed = PlayerPedId()
end

local function relieveStress(action, configKey)
  updatePlayerPed()
  if Config.RemoveStress[configKey].enable and action(playerPed) then
    local val = math.random(Config.RemoveStress[configKey].min, Config.RemoveStress[configKey].max)
    TriggerServerEvent('hud:server:RelieveStress', val)
  end
end


local function addStress(condition, action, configKey)
  updatePlayerPed()
  if Config.AddStress[configKey].enable and condition() then
    action(Config.AddStress[configKey])
  end
end


Citizen.CreateThread(function()
  while true do
    Citizen.Wait(1000) 
    relieveStress(IsPedSwimming, "on_swimming")
    relieveStress(IsPedRunning, "on_running")
    addStress(function()
      return IsPedInAnyVehicle(playerPed, false) and GetEntitySpeed(GetVehiclePedIsIn(playerPed, false)) * 3.6 > 110
    end, function(config)
      TriggerServerEvent('hud:server:GainStress', math.random(config.min, config.max))
    end, "on_fastdrive")
    if Config.AddStress["on_shoot"].enable then
      local weapon = GetSelectedPedWeapon(playerPed)
      if weapon ~= `WEAPON_UNARMED` and IsPedShooting(playerPed) then
        if math.random() < 0.15 and not IsWhitelistedWeaponStress(weapon) then
          TriggerServerEvent('hud:server:GainStress', math.random(Config.AddStress["on_shoot"].min, Config.AddStress["on_shoot"].max))
        end
      end
    end
  end
end)

   
   function IsWhitelistedWeaponStress(weapon)
      if weapon then
         for _, v in pairs(Config.WhitelistedWeaponStress) do
            if weapon == v then
               return true
            end
         end
      end
      return false
   end

   Citizen.CreateThread(function()
   while true do
      local ped = PlayerPedId()
      if tonumber(stress) >= 100 then
         local ShakeIntensity = GetShakeIntensity(stress)
         local FallRepeat = math.random(2, 4)
         local RagdollTimeout = (FallRepeat * 1750)
         ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', ShakeIntensity)
         SetFlash(0, 0, 500, 3000, 500)
   
         if not IsPedRagdoll(ped) and IsPedOnFoot(ped) and not IsPedSwimming(ped) then
            SetPedToRagdollWithFall(ped, RagdollTimeout, RagdollTimeout, 1, GetEntityForwardVector(ped), 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
         end
   
         Wait(500)
         for i=1, FallRepeat, 1 do
            Wait(750)
            DoScreenFadeOut(200)
            Wait(1000)
            DoScreenFadeIn(200)
            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', ShakeIntensity)
            SetFlash(0, 0, 200, 750, 200)
         end
      end
   
      if stress >= 50 then
         local ShakeIntensity = GetShakeIntensity(stress)
         ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', ShakeIntensity)
         SetFlash(0, 0, 500, 2500, 500)
      end
      Wait(GetEffectInterval(stress))
   end
   end)
   
   
   function GetShakeIntensity(stresslevel)
      local retval = 0.05
      local Intensity = Config.Intensity
      for k, v in pairs(Intensity['shake']) do
         if stresslevel >= v.min and stresslevel <= v.max then
            retval = v.intensity
            break
         end
      end
      return retval
   end
   
   function GetEffectInterval(stresslevel)
      local EffectInterval = Config.EffectInterval
      local retval = 10000
      for k, v in pairs(EffectInterval) do
         if stresslevel >= v.min and stresslevel <= v.max then
            retval = v.timeout
            break
         end
      end
      return retval
   end
   
   RegisterNetEvent('hud:client:UpdateStress', function(newStress) -- Add this event with adding stress elsewhere
    stress = newStress
    SendNUIMessage({ data = 'STRESS', stress = math.ceil(newStress) })
   end)
   
   RegisterNetEvent('esx_basicneeds:onEat')
   AddEventHandler('esx_basicneeds:onEat', function()
   if Config.RemoveStress["on_eat"].enable then
      local val = math.random(Config.RemoveStress["on_eat"].min, Config.RemoveStress["on_eat"].max)
      TriggerServerEvent('hud:server:RelieveStress', val)
   end
   end)
   
   RegisterNetEvent('consumables:client:Eat')
   AddEventHandler('consumables:client:Eat', function()
   if Config.RemoveStress["on_eat"].enable then
      local val = math.random(Config.RemoveStress["on_eat"].min, Config.RemoveStress["on_eat"].max)
      TriggerServerEvent('hud:server:RelieveStress', val)
   end
   end)
   
   
   RegisterNetEvent('consumables:client:Drink')
   AddEventHandler('consumables:client:Drink', function()
   if Config.RemoveStress["on_drink"].enable then
      local val = math.random(Config.RemoveStress["on_drink"].min, Config.RemoveStress["on_drink"].max)
      TriggerServerEvent('hud:server:RelieveStress', val)
   end
   end)
   RegisterNetEvent('consumables:client:DrinkAlcohol')
   AddEventHandler('consumables:client:DrinkAlcohol', function()
   if Config.RemoveStress["on_drink"].enable then
      local val = math.random(Config.RemoveStress["on_drink"].min, Config.RemoveStress["on_drink"].max)
      TriggerServerEvent('hud:server:RelieveStress', val)
   end
   end)
   
   RegisterNetEvent('devcore_needs:client:StartEat')
   AddEventHandler('devcore_needs:client:StartEat', function()
   if Config.RemoveStress["on_eat"].enable then
      local val = math.random(Config.RemoveStress["on_eat"].min, Config.RemoveStress["on_eat"].max)
      TriggerServerEvent('hud:server:RelieveStress', val)
   end
   end)
   RegisterNetEvent('devcore_needs:client:DrinkShot')
   AddEventHandler('devcore_needs:client:DrinkShot', function()
   if Config.RemoveStress["on_drink"].enable then
      local val = math.random(Config.RemoveStress["on_drink"].min, Config.RemoveStress["on_drink"].max)
      TriggerServerEvent('hud:server:RelieveStress', val)
   end
   end)
   
   RegisterNetEvent('devcore_needs:client:StartDrink')
   AddEventHandler('devcore_needs:client:StartDrink', function()
   if Config.RemoveStress["on_drink"].enable then
      local val = math.random(Config.RemoveStress["on_drink"].min, Config.RemoveStress["on_drink"].max)
      TriggerServerEvent('hud:server:RelieveStress', val)
   end
   end)
   
   RegisterNetEvent('esx_optionalneeds:onDrink')
   AddEventHandler('esx_optionalneeds:onDrink', function()
   if Config.RemoveStress["on_drink"].enable then
      local val = math.random(Config.RemoveStress["on_drink"].min, Config.RemoveStress["on_drink"].max)
      TriggerServerEvent('hud:server:RelieveStress', val)
   end
   end)
   
   
   RegisterNetEvent('esx_basicneeds:onDrink')
   AddEventHandler('esx_basicneeds:onDrink', function()
   if Config.RemoveStress["on_drink"].enable then
      local val = math.random(Config.RemoveStress["on_drink"].min, Config.RemoveStress["on_drink"].max)
      TriggerServerEvent('hud:server:RelieveStress', val)
   end
   end)
   
   AddEventHandler('esx:onPlayerDeath', function()
   TriggerServerEvent('hud:server:RelieveStress', 10000)
   end)
   
   RegisterNetEvent('hospital:client:RespawnAtHospital')
   AddEventHandler('hospital:client:RespawnAtHospital', function()
   TriggerServerEvent('hud:server:RelieveStress', 10000)
   end)
   
------------------------------------------------------------------------------------------------------------------
