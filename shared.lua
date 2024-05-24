Config = {}

Config = {
    Framework = 'QBCore',  -- QBCore or ESX or OLDQBCore or NewESX
    SeatbeltControl = 'K',  -- Seat belt toggle key (Users can customize this key)
    SpeedMultiplier = 'KM/H',  -- KM/H or MP/H
    Voice = 'pma', -- pma or mumble
    LockedControl = 'L', -- car locked control

    NitroItem = "nitrous", -- item to install nitro to a vehicle
    NitroControl = "H",
    NitroForce = 40.0, -- Nitro force when player using nitro
    RemoveNitroOnpress = 2, -- Determines of how much you want to remove nitro when player press nitro key
    Stress = {
        Enabled = true,  -- Enable or disable stress system
        Chance = 0.1,  -- Default: 10% -- Percentage Stress Chance When Shooting (0-1)
        MinimumLevel = 50,  -- Minimum Stress Level For Screen Shaking
        MinimumSpeed = {
            Buckled = 100,  -- Going over this speed will cause stress when buckled
            Unbuckled = 50  -- Going over this speed will cause stress when unbuckled
        },
        DisableJobs = { 'police', 'ambulance' }  -- Jobs for which stress is disabled
    },

    WhitelistedWeaponStress = {
        `weapon_petrolcan`,
        `weapon_hazardcan`,
        `weapon_fireextinguisher`
    },
}


-- Stress Mechanics Increment
Config.AddStress = {
    ["on_shoot"] = {
        min = 3,
        max = 5,
        enable = true,
    },
    ["on_fastdrive"] = {
        min = 1,
        max = 3,
        enable = true,
    },
}

-- Stress Mechanics Decrement
Config.RemoveStress = {
    ["on_eat"] = {
        min = 5,
        max = 10,
        enable = true,
    },
    ["on_drink"] = {
        min = 5,
        max = 10,
        enable = true,
    },
    ["on_swimming"] = {
        min = 5,
        max = 10,
        enable = true,
    },
    ["on_running"] = {
        min = 5,
        max = 10,
        enable = true,
    },
}

Config.Intensity = {
    ["shake"] = {
        [1] = {
           min = 50,
           max = 60,
           intensity = 0.12,
        },
        [2] = {
           min = 60,
           max = 70,
           intensity = 0.17,
        },
        [3] = {
           min = 70,
           max = 80,
           intensity = 0.22,
        },
        [4] = {
           min = 80,
           max = 90,
           intensity = 0.28,
        },
        [5] = {
           min = 90,
           max = 100,
           intensity = 0.32,
        },
     }
}

Config.EffectInterval = {
    [1] = {
        min = 50,
        max = 60,
        timeout = math.random(50000, 60000)
    },
    [2] = {
        min = 60,
        max = 70,
        timeout = math.random(40000, 50000)
    },
    [3] = {
        min = 70,
        max = 80,
        timeout = math.random(30000, 40000)
    },
    [4] = {
        min = 80,
        max = 90,
        timeout = math.random(20000, 30000)
    },
    [5] = {
        min = 90,
        max = 100,
        timeout = math.random(15000, 20000)
    }
}


-- Vehicle Fuel
Config.GetVehFuel = function(vehicle)
    return GetVehicleFuelLevel(vehicle)  -- exports["LegacyFuel"]:GetFuel(Veh)
end

function GetFramework()
    local Get = nil
    if Config.Framework == "ESX" then
        while Get == nil do
            TriggerEvent('esx:getSharedObject', function(Set) Get = Set end)
            Citizen.Wait(0)
        end
    elseif Config.Framework == "NewESX" then
        Get = exports['es_extended']:getSharedObject()
    elseif Config.Framework == "QBCore" then
        Get = exports["qb-core"]:GetCoreObject()
    elseif Config.Framework == "OLDQBCore" then
        while Get == nil do
            TriggerEvent('QBCore:GetObject', function(Set) Get = Set end)
            Citizen.Wait(200)
        end
    end
    return Get
end
