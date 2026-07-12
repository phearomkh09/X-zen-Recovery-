local QBCore = exports['qb-core']:GetCoreObject()

local Cooldowns = {}

--------------------------------------------------------
-- Save Vehicle To Database
--------------------------------------------------------

RegisterNetEvent('dw-recovery:server:SaveVehicle', function(data)

    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end
    if not data then return end
    if not data.plate then return end

    local coords = json.encode({
        x = data.coords.x,
        y = data.coords.y,
        z = data.coords.z
    })

    exports.oxmysql:update([[
        UPDATE player_vehicles
         SET last_coords = ?,
        last_heading = ?,
        last_saved = UNIX_TIMESTAMP()
        WHERE plate = ?
        AND citizenid = ?
    ]],
    {
        coords,
        data.heading,
        data.plate,
        Player.PlayerData.citizenid
    })

end)

--------------------------------------------------------
-- Get Saved Vehicle
--------------------------------------------------------

QBCore.Functions.CreateCallback(
    'dw-recovery:server:GetSavedVehicle',
    function(source, cb)

        local Player = QBCore.Functions.GetPlayer(source)

        if not Player then
            cb(nil)
            return
        end

        exports.oxmysql:single([[
          SELECT
                plate,
                vehicle,
                mods,
                last_coords,
                last_heading,
                state
          FROM player_vehicles
          WHERE citizenid = ?
          AND last_coords IS NOT NULL
          ORDER BY last_saved DESC
          LIMIT 1
         ]],
        {
            Player.PlayerData.citizenid
        },

        function(result)

            if not result then
                cb(nil)
                return
            end
                
             if result.state == 2 then
               cb({
               impounded = true
               })
             return
            end
 
            if not result.last_coords then
                cb(nil)
                return
            end

            result.coords = json.decode(result.last_coords)
            result.heading = result.last_heading
            result.model = result.vehicle

            if result.mods then
                result.props = json.decode(result.mods)
            end

            cb(result)

        end)

    end
)
--------------------------------------------------------
-- Pay Recovery
--------------------------------------------------------

QBCore.Functions.CreateCallback(
    'dw-recovery:server:PayRecovery',
    function(source, cb)

        local Player = QBCore.Functions.GetPlayer(source)

        if not Player then
            cb(false)
            return
        end

        local citizenid = Player.PlayerData.citizenid

        if Cooldowns[citizenid] and Cooldowns[citizenid] > os.time() then

            TriggerClientEvent('ox_lib:notify', source, {
                type = 'error',
                description = Config.Notify.Cooldown
            })

            cb(false)
            return

        end

        if Config.RecoveryFee > 0 then

            local account = Config.UseBank and 'bank' or 'cash'

            if Player.PlayerData.money[account] < Config.RecoveryFee then

                TriggerClientEvent('ox_lib:notify', source, {
                    type = 'error',
                    description = Config.Notify.Money
                })

                cb(false)
                return
            end

            Player.Functions.RemoveMoney(
                account,
                Config.RecoveryFee,
                'vehicle-recovery'
            )

        end

        Cooldowns[citizenid] = os.time() + Config.Cooldown

        cb(true)

    end
)

--------------------------------------------------------
-- Check Vehicle Already Spawned
--------------------------------------------------------

QBCore.Functions.CreateCallback(
    'dw-recovery:server:VehicleExists',
    function(source, cb, plate)

        for _, veh in ipairs(GetGamePool('CVehicle')) do

            if DoesEntityExist(veh) then

                if GetVehicleNumberPlateText(veh) == plate then
                    cb(true)
                    return
                end

            end

        end

        cb(false)

    end
)

--------------------------------------------------------
-- Set Vehicle Out
--------------------------------------------------------

RegisterNetEvent(
    'dw-recovery:server:SetVehicleOut',
    function(plate)

        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return end

        exports.oxmysql:update([[
            UPDATE player_vehicles
            SET state = 0
            WHERE plate = ?
            AND citizenid = ?
        ]],
        {
            plate,
            Player.PlayerData.citizenid
        })

    end
)

--------------------------------------------------------
-- Clear Last Position
--------------------------------------------------------

RegisterNetEvent(
    'dw-recovery:server:ClearLastPosition',
    function(plate)

        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return end

        exports.oxmysql:update([[
            UPDATE player_vehicles
            SET last_coords = NULL,
                last_heading = 0
            WHERE plate = ?
            AND citizenid = ?
        ]],
        {
            plate,
            Player.PlayerData.citizenid
        })

    end
)

--------------------------------------------------------
-- Cleanup
--------------------------------------------------------

AddEventHandler('playerDropped', function()

    local Player = QBCore.Functions.GetPlayer(source)

    if Player then
        Cooldowns[Player.PlayerData.citizenid] = nil
    end

end)