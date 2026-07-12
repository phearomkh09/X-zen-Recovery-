Config = {}

--------------------------------------------------------
-- Command / Key
--------------------------------------------------------

Config.Command = 'recovercar'
Config.Key = 'F10'

--------------------------------------------------------
-- Menu
--------------------------------------------------------

Config.MenuTitle = 'Vehicle Recovery'

--------------------------------------------------------
-- Recovery
--------------------------------------------------------

Config.RecoveryFee = 500      -- 0 = Free
Config.UseBank = true         -- true = Bank | false = Cash
Config.Cooldown = 60          -- Seconds

--------------------------------------------------------
-- Spawn
--------------------------------------------------------

Config.EngineOn = true

-- true = Warp Player Into Vehicle
-- false = Spawn Vehicle Only
Config.WarpIntoVehicle = false

--------------------------------------------------------
-- Notifications
--------------------------------------------------------

Config.Notify = {

    Success = 'Vehicle recovered successfully.',

    Failed = 'No recoverable vehicle found.',

    Cooldown = 'Please wait before using recovery again.',

    Money = 'You do not have enough money.',

    AlreadySpawned = 'Your vehicle is already spawned.',

    NoVehicle = 'No saved vehicle found.',

    Waypoint = 'Waypoint has been set.'

}

--------------------------------------------------------
-- ox_lib Menu
--------------------------------------------------------

Config.Menu = {

    {
        title = '📍 Recover Last Vehicle',
        description = 'Recover your last parked vehicle.',
        icon = 'car',
        event = 'dw-recovery:client:Recover'
    },

    {
        title = '📌 Show Parking Location',
        description = 'Create waypoint to your last parking location.',
        icon = 'location-dot',
        event = 'dw-recovery:client:Waypoint'
    }

}