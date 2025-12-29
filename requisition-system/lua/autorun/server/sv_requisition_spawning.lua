-- Server-side vehicle spawning logic

ReqSystem.SpawnedVehicles = ReqSystem.SpawnedVehicles or {}
ReqSystem.PlayerCooldowns = ReqSystem.PlayerCooldowns or {}

-- Check if entity is a vehicle (including LVS/Simfphys)
function ReqSystem:IsVehicleEntity(ent)
    if not IsValid(ent) then return false end
    
    return ent:IsVehicle() or 
           string.match(ent:GetClass(), "^lvs_") or 
           string.match(ent:GetClass(), "^sim_fphys_")
end

-- Track spawned vehicles per player
function ReqSystem:GetPlayerVehicleCount(ply)
    if not IsValid(ply) then return 0 end
    
    local steamid = ply:SteamID()
    if not self.SpawnedVehicles[steamid] then
        return 0
    end
    
    local count = 0
    for _, veh in pairs(self.SpawnedVehicles[steamid]) do
        if IsValid(veh) then
            count = count + 1
        end
    end
    
    return count
end

-- Add vehicle to player's spawned list
function ReqSystem:TrackVehicle(ply, vehicle)
    if not IsValid(ply) or not IsValid(vehicle) then return end
    
    local steamid = ply:SteamID()
    if not self.SpawnedVehicles[steamid] then
        self.SpawnedVehicles[steamid] = {}
    end
    
    table.insert(self.SpawnedVehicles[steamid], vehicle)
    
    -- Mark vehicle with owner
    vehicle:SetNWString("ReqSystem_Owner", steamid)
    vehicle:SetNWString("ReqSystem_OwnerName", ply:Nick())
end

-- Remove vehicle from tracking
function ReqSystem:UntrackVehicle(vehicle)
    if not IsValid(vehicle) then return end
    
    local steamid = vehicle:GetNWString("ReqSystem_Owner", "")
    if steamid == "" then return end
    
    if self.SpawnedVehicles[steamid] then
        for i, veh in ipairs(self.SpawnedVehicles[steamid]) do
            if veh == vehicle then
                table.remove(self.SpawnedVehicles[steamid], i)
                break
            end
        end
    end
end

-- Check if player is on cooldown for a vehicle
function ReqSystem:IsOnCooldown(ply, vehicleId)
    if not self.Config.VehicleSettings.cooldown_enabled then return false end
    if not IsValid(ply) then return true end
    
    local steamid = ply:SteamID()
    if not self.PlayerCooldowns[steamid] then return false end
    
    local cooldownEnd = self.PlayerCooldowns[steamid][vehicleId]
    if not cooldownEnd then return false end
    
    return CurTime() < cooldownEnd
end

-- Get remaining cooldown time
function ReqSystem:GetCooldownTime(ply, vehicleId)
    if not self.Config.VehicleSettings.cooldown_enabled then return 0 end
    if not IsValid(ply) then return 0 end
    
    local steamid = ply:SteamID()
    if not self.PlayerCooldowns[steamid] then return 0 end
    
    local cooldownEnd = self.PlayerCooldowns[steamid][vehicleId]
    if not cooldownEnd then return 0 end
    
    local remaining = cooldownEnd - CurTime()
    return math.max(0, remaining)
end

-- Set cooldown for player
function ReqSystem:SetCooldown(ply, vehicleId)
    if not self.Config.VehicleSettings.cooldown_enabled then return end
    if not IsValid(ply) then return end
    
    local steamid = ply:SteamID()
    if not self.PlayerCooldowns[steamid] then
        self.PlayerCooldowns[steamid] = {}
    end
    
    self.PlayerCooldowns[steamid][vehicleId] = CurTime() + self.Config.VehicleSettings.cooldown_time
end

-- Find spawn position at center of area
function ReqSystem:FindSpawnPosition(area)
    if not area then return nil end
    
    local minPos = area.min_pos
    local maxPos = area.max_pos
    
    -- Use center X/Y of spawn area
    local centerX = (minPos.x + maxPos.x) / 2
    local centerY = (minPos.y + maxPos.y) / 2
    local highestZ = math.max(minPos.z, maxPos.z)
    
    -- Trace from high point down to find ground
    local tr = util.TraceLine({
        start = Vector(centerX, centerY, highestZ + 200),
        endpos = Vector(centerX, centerY, highestZ - 1000),
        mask = MASK_SOLID_BRUSHONLY
    })
    
    if tr.Hit then
        return tr.HitPos + Vector(0, 0, self.Config.VehicleSettings.spawn_height_offset)
    end
    
    -- Fallback: use highest Z point
    return Vector(centerX, centerY, highestZ + self.Config.VehicleSettings.spawn_height_offset)
end

-- Spawn vehicle for player
function ReqSystem:SpawnVehicle(ply, terminalId, vehicleId, skin, bodygroups)
    if not IsValid(ply) then return false, "Invalid player" end
    
    -- Default values for skin and bodygroups
    skin = skin or 0
    bodygroups = bodygroups or {}
    
    -- Get terminal data
    local terminal = self.Terminals[terminalId]
    if not terminal then return false, "Invalid terminal" end
    
    -- Get area data
    local area = self.Areas[terminal.area_id]
    if not area then return false, "Terminal has no spawn area assigned" end
    
    -- Get vehicle data
    local vehicleData = self.Vehicles[vehicleId]
    if not vehicleData then return false, "Invalid vehicle" end
    
    -- Check if vehicle is available at this terminal
    if not self.TerminalVehicles[terminalId] or not self.TerminalVehicles[terminalId][vehicleId] then
        return false, "Vehicle not available at this terminal"
    end
    
    -- Check permissions
    local canSpawn, reason = self:PlayerCanSpawnVehicle(ply, vehicleData)
    if not canSpawn then
        return false, reason
    end
    
    -- Check cooldown
    if self:IsOnCooldown(ply, vehicleId) then
        local remaining = math.ceil(self:GetCooldownTime(ply, vehicleId))
        return false, string.format("On cooldown for %d seconds", remaining)
    end
    
    -- Check vehicle limit
    local currentCount = self:GetPlayerVehicleCount(ply)
    if currentCount >= self.Config.VehicleSettings.max_vehicles_per_player then
        return false, string.format("Vehicle limit reached (%d/%d)", currentCount, self.Config.VehicleSettings.max_vehicles_per_player)
    end
    
    -- Find spawn position
    local spawnPos = self:FindSpawnPosition(area)
    if not spawnPos then
        return false, "Could not find suitable spawn location"
    end
    
    -- Spawn the vehicle using the class from database
    local vehicle = ents.Create(vehicleData.class)
    if not IsValid(vehicle) then
        return false, "Failed to create vehicle entity"
    end
    
    -- Set position and angle (use spawn area's designated angle)
    vehicle:SetPos(spawnPos)
    vehicle:SetAngles(Angle(0, area.spawn_angle or 0, 0))
    
    -- Set model from database if provided (for custom vehicles like TDM Cars)
    if vehicleData.model and vehicleData.model ~= "" then
        vehicle:SetModel(vehicleData.model)
    end
    
    -- Set KeyValues from database (vehicle script, etc.) BEFORE spawning
    if vehicleData.key_values and next(vehicleData.key_values) then
        for k, v in pairs(vehicleData.key_values) do
            vehicle:SetKeyValue(k, v)
        end
    end
    
    vehicle:Spawn()
    vehicle:Activate()
    
    -- Apply skin
    if skin and skin > 0 then
        vehicle:SetSkin(skin)
    end
    
    -- Apply bodygroups
    if bodygroups and next(bodygroups) then
        for bgId, bgValue in pairs(bodygroups) do
            vehicle:SetBodygroup(bgId, bgValue)
        end
    end
    
    -- Set owner
    if vehicle.CPPISetOwner then
        vehicle:CPPISetOwner(ply)
    end
    
    -- Track vehicle
    self:TrackVehicle(ply, vehicle)
    
    -- Store spawn area ID for return tracking
    vehicle:SetNWInt("ReqSystem_SpawnAreaID", terminal.area_id)
    
    -- Set cooldown
    self:SetCooldown(ply, vehicleId)
    
    -- Execute custom function if provided
    if vehicleData.custom_function and vehicleData.custom_function ~= "" then
        local success, err = pcall(function()
            local func = CompileString(vehicleData.custom_function, "VehicleCustomFunction")
            if func then
                func(ply, vehicle, vehicleData)
            end
        end)
        
        if not success then
            -- Error executing custom function
        end
    end
    
    -- Vehicle spawned successfully
    
    return true, "Vehicle spawned successfully"
end

-- Clean up player vehicles on disconnect
hook.Add("PlayerDisconnected", "ReqSystem_CleanupVehicles", function(ply)
    if not ReqSystem.Config.VehicleSettings.despawn_on_disconnect then return end
    
    local steamid = ply:SteamID()
    if ReqSystem.SpawnedVehicles[steamid] then
        for _, vehicle in pairs(ReqSystem.SpawnedVehicles[steamid]) do
            if IsValid(vehicle) then
                vehicle:Remove()
            end
        end
        ReqSystem.SpawnedVehicles[steamid] = nil
    end
    
    -- Clear cooldowns
    ReqSystem.PlayerCooldowns[steamid] = nil
end)

-- Clean up vehicles when removed
hook.Add("EntityRemoved", "ReqSystem_VehicleRemoved", function(ent)
    if ReqSystem:IsVehicleEntity(ent) then
        ReqSystem:UntrackVehicle(ent)
    end
end)

-- Return vehicle to system
function ReqSystem:ReturnVehicle(ply, vehicle)
    if not IsValid(ply) or not IsValid(vehicle) then 
        return false, "Invalid player or vehicle" 
    end
    
    -- Check if vehicle belongs to player
    local owner = vehicle:GetNWString("ReqSystem_Owner", "")
    if owner ~= ply:SteamID() then
        return false, "This vehicle doesn't belong to you"
    end
    
    -- Check if vehicle is in spawn area
    local areaId = vehicle:GetNWInt("ReqSystem_SpawnAreaID", 0)
    if areaId == 0 then
        return false, "Vehicle has no spawn area assigned"
    end
    
    local area = self.Areas[areaId]
    if not area then
        return false, "Spawn area no longer exists"
    end
    
    -- Check if vehicle position is within spawn area bounds (X and Y only, ignore Z)
    local vehPos = vehicle:GetPos()
    
    -- Normalize bounds
    local minX = math.min(area.min_pos.x, area.max_pos.x)
    local maxX = math.max(area.min_pos.x, area.max_pos.x)
    local minY = math.min(area.min_pos.y, area.max_pos.y)
    local maxY = math.max(area.min_pos.y, area.max_pos.y)
    
    -- Check X and Y only (vehicles may be at different Z heights on ground)
    if not (vehPos.x >= minX and vehPos.x <= maxX and vehPos.y >= minY and vehPos.y <= maxY) then
        return false, "Vehicle must be in the spawn area to return it"
    end
    
    -- Remove vehicle and clear tracking
    self:UntrackVehicle(vehicle)
    vehicle:Remove()
    
    return true, "Vehicle returned successfully"
end

-- Network receiver for spawn requests
net.Receive("ReqSystem_SpawnVehicle", function(len, ply)
    local terminalId = net.ReadInt(32)
    local vehicleId = net.ReadInt(32)
    local skin = net.ReadInt(8)
    local bodygroups = net.ReadTable()
    
    local success, message = ReqSystem:SpawnVehicle(ply, terminalId, vehicleId, skin, bodygroups)
    
    -- Send response back to client
    net.Start("ReqSystem_SpawnVehicle")
    net.WriteBool(success)
    net.WriteString(message)
    net.Send(ply)
    
    if success then
        ply:ChatPrint("[Requisition] " .. message)
    else
        ply:ChatPrint("[Requisition] ERROR: " .. message)
    end
end)

-- Network receiver for return requests
net.Receive("ReqSystem_ReturnVehicle", function(len, ply)
    local vehicle = net.ReadEntity()
    
    local success, message = ReqSystem:ReturnVehicle(ply, vehicle)
    
    if success then
        ply:ChatPrint("[Requisition] " .. message)
    else
        ply:ChatPrint("[Requisition] ERROR: " .. message)
    end
end)

-- Server-side spawning loaded
