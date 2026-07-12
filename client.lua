local QBCore = exports['qb-core']:GetCoreObject()

local LastVehicle = nil
local MenuOpen = false

--------------------------------------------------------
-- Command
--------------------------------------------------------

RegisterCommand(Config.Command, function()
    OpenRecoveryMenu()
end)

--------------------------------------------------------
-- Key Mapping
--------------------------------------------------------

RegisterKeyMapping(
    Config.Command,
    'Vehicle Recovery',
    'keyboard',
    Config.Key
)

--------------------------------------------------------
-- ox_lib Menu
--------------------------------------------------------

function OpenRecoveryMenu()

    if MenuOpen then
        return
    end

    MenuOpen = true

    lib.registerContext({

        id = 'dw_vehicle_recovery',

        title = Config.MenuTitle,

        options = Config.Menu

    })

    lib.showContext('dw_vehicle_recovery')

    MenuOpen = false

end

--------------------------------------------------------
-- Save Last Vehicle Position
--------------------------------------------------------

CreateThread(function()

    while true do

        Wait(1000)

        local ped = PlayerPedId()

        if IsPedInAnyVehicle(ped, false) then

            local vehicle = GetVehiclePedIsIn(ped, false)

            if GetPedInVehicleSeat(vehicle, -1) == ped then
             LastVehicle = VehToNet(vehicle)
         end

        end

         if LastVehicle and not IsPedInAnyVehicle(ped, false) then

            local vehicle = NetToVeh(LastVehicle)

             if DoesEntityExist(vehicle) then

             if not DoesEntityExist(vehicle) then
               LastVehicle = nil
               return
           end

                local coords = GetEntityCoords(vehicle)
                local heading = GetEntityHeading(vehicle)

                TriggerServerEvent(
                'dw-recovery:server:SaveVehicle',
                    {
                    plate = QBCore.Functions.GetPlate(vehicle),
                    model = GetEntityModel(vehicle),
                    coords = coords,
                    heading = heading,
                    props = QBCore.Functions.GetVehicleProperties(vehicle)
               }
            )

            end

            LastVehicle = nil

        end

    end

end)

--------------------------------------------------------
-- Recover Vehicle
--------------------------------------------------------

RegisterNetEvent('dw-recovery:client:Recover', function()

    QBCore.Functions.TriggerCallback(
        'dw-recovery:server:GetSavedVehicle',
        function(data)

                    if not data then
                      lib.notify({
                      title = 'Vehicle Recovery',
                      description = 'No saved vehicle found.',
                    type = 'error'
                   })
                return
            end

                   if data.impounded then
                     lib.notify({
                     title = 'Vehicle Recovery',
                     description = 'This vehicle has been impounded by Police.',
                    type = 'error'
                   })
                return
              end

            -- Check if vehicle already exists
            QBCore.Functions.TriggerCallback(
                'dw-recovery:server:VehicleExists',
                function(exists)

                    if exists then
                        lib.notify({
                            title = 'Vehicle Recovery',
                            description = Config.Notify.AlreadySpawned,
                            type = 'error'
                        })
                        return
                    end

                    -- Pay recovery fee
                    QBCore.Functions.TriggerCallback(
                        'dw-recovery:server:PayRecovery',
                        function(success)

                            if not success then
                                return
                            end

                            local coords = vector3(
                                data.coords.x,
                                data.coords.y,
                                data.coords.z
                            )

                            QBCore.Functions.SpawnVehicle(
                                data.model,
                                function(vehicle)

                                    if vehicle == 0 then
                                        lib.notify({
                                            title = 'Vehicle Recovery',
                                            description = Config.Notify.Failed,
                                            type = 'error'
                                        })
                                        return
                                    end

                                    SetEntityHeading(vehicle, data.heading)
                                    SetVehicleNumberPlateText(vehicle, data.plate)

                                    if data.props then
                                        QBCore.Functions.SetVehicleProperties(vehicle, data.props)
                                    end

                                    if GetResourceState('LegacyFuel') == 'started' then
                                        exports['LegacyFuel']:SetFuel(vehicle, 100)
                                    end

                                    SetVehicleEngineHealth(vehicle, 1000.0)
                                    SetVehicleBodyHealth(vehicle, 1000.0)

                                    SetVehicleEngineOn(
                                        vehicle,
                                        Config.EngineOn,
                                        true,
                                        false
                                    )

                                    TriggerEvent(
                                        'vehiclekeys:client:SetOwner',
                                        data.plate
                                    )

                                    if Config.WarpIntoVehicle then
                                        TaskWarpPedIntoVehicle(
                                            PlayerPedId(),
                                            vehicle,
                                            -1
                                        )
                                    end

                                    TriggerServerEvent(
                                        'dw-recovery:server:SetVehicleOut',
                                        data.plate
                                    )

                                    TriggerServerEvent(
                                        'dw-recovery:server:ClearLastPosition',
                                        data.plate
                                    )

                                    lib.notify({
                                        title = 'Vehicle Recovery',
                                        description = Config.Notify.Success,
                                        type = 'success'
                                    })

                                end,
                                coords,
                                true
                            )

                        end
                    )

                end,
                data.plate
            )

        end
    )

end)

--------------------------------------------------------
-- Show Parking Waypoint
--------------------------------------------------------

RegisterNetEvent('dw-recovery:client:Waypoint', function()

    QBCore.Functions.TriggerCallback(
        'dw-recovery:server:GetSavedVehicle',
        function(data)

            if not data then

                lib.notify({
                    title = 'Vehicle Recovery',
                    description = 'No saved parking location.',
                    type = 'error'
                })

                return

            end

            SetNewWaypoint(
                data.coords.x,
                data.coords.y
            )

            lib.notify({
                title = 'Vehicle Recovery',
                description = Config.Notify.Waypoint,
                type = 'success'
            })

        end
    )

end)

--------------------------------------------------------
-- Resource Started
--------------------------------------------------------

CreateThread(function()

    while not LocalPlayer.state.isLoggedIn do
        Wait(500)
    end

    print('^2[dw-vehicle-recovery]^7 Loaded Successfully')

end)