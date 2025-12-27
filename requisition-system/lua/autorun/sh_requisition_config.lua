-- Vehicle Requisition System Configuration
-- This file is shared between server and client

ReqSystem = ReqSystem or {}
ReqSystem.Config = {}

-- Admin ranks that can access !reqadmin and manage requisitions
-- Add your admin ranks here (case sensitive)
ReqSystem.Config.AdminRanks = {
    ["superadmin"] = true,
    ["admin"] = true,
    -- Add more admin ranks as needed
}

-- Chat command to open the admin menu
ReqSystem.Config.AdminCommand = "!reqadmin"

-- Database table names
ReqSystem.Config.Tables = {
    areas = "requisition_areas",
    terminals = "requisition_terminals",
    vehicles = "requisition_vehicles",
    terminal_vehicles = "requisition_terminal_vehicles"
}

-- Vehicle spawn settings
ReqSystem.Config.VehicleSettings = {
    despawn_on_disconnect = true, -- Auto-remove vehicles when player disconnects
    cooldown_enabled = true, -- Enable spawn cooldowns
    cooldown_time = 60, -- Cooldown time in seconds
    max_vehicles_per_player = 3, -- Maximum vehicles a player can have spawned
    spawn_height_offset = 50, -- Height above ground to spawn vehicles (increased for LVS vehicles)
}

-- Terminal settings
ReqSystem.Config.TerminalSettings = {
    default_model = "models/props_combine/combine_interface001.mdl", -- Default terminal model
    display_name = "Requisition Terminal", -- Text displayed above terminal
    text_height_offset = 60, -- Height above terminal to display text (increase to raise text)
    show_terminal_id = false, -- Show terminal ID number
    show_use_hint = true, -- Show "Press E to use" text
}

-- Function to check if a player is an admin
function ReqSystem:IsAdmin(ply)
    if not IsValid(ply) then return false end
    local usergroup = ply:GetUserGroup()
    return self.Config.AdminRanks[usergroup] == true
end

-- Function to check if player can spawn a specific vehicle
function ReqSystem:PlayerCanSpawnVehicle(ply, vehicleData)
    if not IsValid(ply) then return false, "Invalid player" end
    if not vehicleData then return false, "Invalid vehicle data" end
    
    -- Check jobs
    if vehicleData.jobs and #vehicleData.jobs > 0 then
        local playerJob = team.GetName(ply:Team())
        local hasJob = false
        for _, job in ipairs(vehicleData.jobs) do
            if job == playerJob then
                hasJob = true
                break
            end
        end
        if not hasJob then
            return false, "You don't have the required job"
        end
    end
    
    -- Check qualifications (if qualification system is loaded)
    if QualSystem and vehicleData.qualifications and #vehicleData.qualifications > 0 then
        for _, qual in ipairs(vehicleData.qualifications) do
            if not QualSystem:PlayerHasQualification(ply, qual) then
                return false, "Missing qualification: " .. qual
            end
        end
    end
    
    return true, "OK"
end

-- Utility function to format position as string
function ReqSystem:FormatPosition(pos)
    if not pos then return "Unknown" end
    return string.format("(%.0f, %.0f, %.0f)", pos.x, pos.y, pos.z)
end

-- Utility function to check if position is within bounds
function ReqSystem:IsPositionInBounds(pos, minPos, maxPos)
    if not pos or not minPos or not maxPos then return false end
    
    -- Normalize bounds to ensure min is actually minimum
    local actualMin = Vector(
        math.min(minPos.x, maxPos.x),
        math.min(minPos.y, maxPos.y),
        math.min(minPos.z, maxPos.z)
    )
    
    local actualMax = Vector(
        math.max(minPos.x, maxPos.x),
        math.max(minPos.y, maxPos.y),
        math.max(minPos.z, maxPos.z)
    )
    
    return pos.x >= actualMin.x and pos.x <= actualMax.x and
           pos.y >= actualMin.y and pos.y <= actualMax.y and
           pos.z >= actualMin.z and pos.z <= actualMax.z
end

-- Utility function to get random position within bounds
function ReqSystem:GetRandomPositionInBounds(minPos, maxPos)
    if not minPos or not maxPos then return nil end
    
    return Vector(
        math.Rand(minPos.x, maxPos.x),
        math.Rand(minPos.y, maxPos.y),
        math.Rand(minPos.z, maxPos.z)
    )
end

-- Config loaded
