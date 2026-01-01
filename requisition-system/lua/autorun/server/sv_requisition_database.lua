-- Server-side database and requisition management

-- Helper function for colored chat messages
local function ReqChatPrint(ply, message, isError)
    if not IsValid(ply) then return end
    
    net.Start("ReqSystem_ColoredChat")
    net.WriteString(message)
    net.WriteBool(isError or false)
    net.Send(ply)
end

-- Network strings
util.AddNetworkString("ReqSystem_ColoredChat")
util.AddNetworkString("ReqSystem_OpenTerminal")
util.AddNetworkString("ReqSystem_OpenTerminalAdmin")
util.AddNetworkString("ReqSystem_OpenGlobalAdmin")
util.AddNetworkString("ReqSystem_SendTerminalData")
util.AddNetworkString("ReqSystem_SendVehicles")
util.AddNetworkString("ReqSystem_SendAreas")
util.AddNetworkString("ReqSystem_SendTerminals")
util.AddNetworkString("ReqSystem_SpawnVehicle")
util.AddNetworkString("ReqSystem_SaveTerminalConfig")
util.AddNetworkString("ReqSystem_SaveVehicle")
util.AddNetworkString("ReqSystem_DeleteVehicle")
util.AddNetworkString("ReqSystem_DeleteTerminal")
util.AddNetworkString("ReqSystem_DeleteArea")
util.AddNetworkString("ReqSystem_CreateArea")
util.AddNetworkString("ReqSystem_VisualizeArea")
util.AddNetworkString("ReqSystem_SaveTerminals")
util.AddNetworkString("ReqSystem_LoadTerminalsResponse")
util.AddNetworkString("ReqSystem_ReturnVehicle")

ReqSystem.Areas = ReqSystem.Areas or {}
ReqSystem.Terminals = ReqSystem.Terminals or {}
ReqSystem.Vehicles = ReqSystem.Vehicles or {}
ReqSystem.TerminalVehicles = ReqSystem.TerminalVehicles or {}
ReqSystem.RuntimeTerminalCounter = ReqSystem.RuntimeTerminalCounter or 0

-- Initialize database
function ReqSystem:InitializeDatabase()
    local areasTable = self.Config.Tables.areas
    local terminalsTable = self.Config.Tables.terminals
    local vehiclesTable = self.Config.Tables.vehicles
    local terminalVehiclesTable = self.Config.Tables.terminal_vehicles
    
    -- Create areas table
    sql.Query(string.format([[
        CREATE TABLE IF NOT EXISTS %s (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            min_x REAL NOT NULL,
            min_y REAL NOT NULL,
            min_z REAL NOT NULL,
            max_x REAL NOT NULL,
            max_y REAL NOT NULL,
            max_z REAL NOT NULL,
            spawn_angle REAL NOT NULL DEFAULT 0,
            created_at INTEGER
        )
    ]], areasTable))
    
    -- Add spawn_angle column if it doesn't exist (for existing databases)
    sql.Query(string.format("ALTER TABLE %s ADD COLUMN spawn_angle REAL DEFAULT 0", areasTable))
    
    -- Create terminals table
    sql.Query(string.format([[
        CREATE TABLE IF NOT EXISTS %s (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pos_x REAL NOT NULL,
            pos_y REAL NOT NULL,
            pos_z REAL NOT NULL,
            ang_p REAL NOT NULL,
            ang_y REAL NOT NULL,
            ang_r REAL NOT NULL,
            area_id INTEGER,
            created_at INTEGER
        )
    ]], terminalsTable))
    
    -- Create vehicles table
    sql.Query(string.format([[
        CREATE TABLE IF NOT EXISTS %s (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            model TEXT NOT NULL,
            class TEXT NOT NULL,
            jobs TEXT,
            qualifications TEXT,
            custom_function TEXT,
            key_values TEXT,
            created_at INTEGER
        )
    ]], vehiclesTable))
    
    -- Add key_values column if it doesn't exist (for existing databases)
    sql.Query(string.format("ALTER TABLE %s ADD COLUMN key_values TEXT", vehiclesTable))

    -- Add model and name columns to terminals if they don't exist (for existing databases)
    sql.Query(string.format("ALTER TABLE %s ADD COLUMN model TEXT", terminalsTable))
    sql.Query(string.format("ALTER TABLE %s ADD COLUMN name TEXT", terminalsTable))
    
    -- Create terminal_vehicles junction table
    sql.Query(string.format([[
        CREATE TABLE IF NOT EXISTS %s (
            terminal_id INTEGER NOT NULL,
            vehicle_id INTEGER NOT NULL,
            PRIMARY KEY (terminal_id, vehicle_id)
        )
    ]], terminalVehiclesTable))
    
    -- Create saved_terminals table for map-specific spawns
    sql.Query([[
        CREATE TABLE IF NOT EXISTS requisition_saved_terminals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            map_name TEXT NOT NULL,
            pos_x REAL NOT NULL,
            pos_y REAL NOT NULL,
            pos_z REAL NOT NULL,
            ang_p REAL NOT NULL,
            ang_y REAL NOT NULL,
            ang_r REAL NOT NULL,
            area_id INTEGER,
            model TEXT,
            name TEXT,
            created_at INTEGER
        )
    ]])

    -- Create saved_terminal_vehicles junction table
    sql.Query([[
        CREATE TABLE IF NOT EXISTS requisition_saved_terminal_vehicles (
            saved_terminal_id INTEGER NOT NULL,
            vehicle_id INTEGER NOT NULL,
            PRIMARY KEY (saved_terminal_id, vehicle_id)
        )
    ]])

    -- Add model and name columns to saved_terminals if they don't exist (for existing databases)
    sql.Query("ALTER TABLE requisition_saved_terminals ADD COLUMN model TEXT")
    sql.Query("ALTER TABLE requisition_saved_terminals ADD COLUMN name TEXT")

    -- Database initialized
end

-- Load all areas from database
function ReqSystem:LoadAreas()
    local areasTable = self.Config.Tables.areas
    local query = string.format("SELECT * FROM %s", areasTable)
    local results = sql.Query(query)
    
    self.Areas = {}
    
    if results then
        for _, row in ipairs(results) do
            local areaData = {
                id = tonumber(row.id),
                name = row.name,
                min_pos = Vector(tonumber(row.min_x), tonumber(row.min_y), tonumber(row.min_z)),
                max_pos = Vector(tonumber(row.max_x), tonumber(row.max_y), tonumber(row.max_z)),
                spawn_angle = tonumber(row.spawn_angle) or 0,
                created_at = tonumber(row.created_at)
            }
            self.Areas[areaData.id] = areaData
        end
        -- Loaded spawn areas
    end
end

-- Load all terminals from database
function ReqSystem:LoadTerminals()
    local terminalsTable = self.Config.Tables.terminals
    local query = string.format("SELECT * FROM %s", terminalsTable)
    local results = sql.Query(query)

    self.Terminals = {}

    if results then
        for _, row in ipairs(results) do
            local terminalData = {
                id = tonumber(row.id),
                pos = Vector(tonumber(row.pos_x), tonumber(row.pos_y), tonumber(row.pos_z)),
                ang = Angle(tonumber(row.ang_p), tonumber(row.ang_y), tonumber(row.ang_r)),
                area_id = tonumber(row.area_id),
                model = row.model,
                name = row.name,
                created_at = tonumber(row.created_at)
            }
            self.Terminals[terminalData.id] = terminalData
        end
        -- Loaded terminals
    end
end

-- Load all vehicles from database
function ReqSystem:LoadVehicles()
    local vehiclesTable = self.Config.Tables.vehicles
    local query = string.format("SELECT * FROM %s", vehiclesTable)
    local results = sql.Query(query)
    
    self.Vehicles = {}
    
    if results then
        for _, row in ipairs(results) do
            local vehicleData = {
                id = tonumber(row.id),
                name = row.name,
                model = row.model,
                class = row.class,
                jobs = util.JSONToTable(row.jobs or "[]") or {},
                qualifications = util.JSONToTable(row.qualifications or "[]") or {},
                custom_function = row.custom_function or "",
                key_values = util.JSONToTable(row.key_values or "{}") or {},
                created_at = tonumber(row.created_at)
            }
            self.Vehicles[vehicleData.id] = vehicleData
        end
        -- Loaded vehicles
    end
end

-- Load terminal-vehicle relationships
function ReqSystem:LoadTerminalVehicles()
    local terminalVehiclesTable = self.Config.Tables.terminal_vehicles
    local query = string.format("SELECT * FROM %s", terminalVehiclesTable)
    local results = sql.Query(query)
    
    self.TerminalVehicles = {}
    
    if results then
        for _, row in ipairs(results) do
            local terminalId = tonumber(row.terminal_id)
            local vehicleId = tonumber(row.vehicle_id)
            
            if not self.TerminalVehicles[terminalId] then
                self.TerminalVehicles[terminalId] = {}
            end
            self.TerminalVehicles[terminalId][vehicleId] = true
        end
        -- Loaded terminal-vehicle relationships
    end
end

-- Create a new spawn area
function ReqSystem:CreateArea(name, minPos, maxPos, spawnAngle)
    local areasTable = self.Config.Tables.areas
    
    local query = string.format([[
        INSERT INTO %s (name, min_x, min_y, min_z, max_x, max_y, max_z, spawn_angle, created_at)
        VALUES (%s, %f, %f, %f, %f, %f, %f, %f, %d)
    ]], areasTable,
        sql.SQLStr(name),
        minPos.x, minPos.y, minPos.z,
        maxPos.x, maxPos.y, maxPos.z,
        spawnAngle or 0,
        os.time()
    )
    
    local result = sql.Query(query)
    if result == false then
        -- Error creating area
        return false
    end
    
    self:LoadAreas()
    self:SyncAreasToClients()
    return true
end

-- Delete a spawn area
function ReqSystem:DeleteArea(areaId)
    local areasTable = self.Config.Tables.areas
    local query = string.format("DELETE FROM %s WHERE id = %d", areasTable, areaId)
    sql.Query(query)
    
    self:LoadAreas()
    self:SyncAreasToClients()
end

-- Register a terminal (called by entity)
function ReqSystem:RegisterTerminal(pos, ang, areaId)
    local terminalsTable = self.Config.Tables.terminals

    -- Get the last terminal ID to generate the next terminal number
    local countQuery = string.format("SELECT COUNT(*) as count FROM %s", terminalsTable)
    local countResult = sql.Query(countQuery)
    local terminalNumber = 1
    if countResult and countResult[1] then
        terminalNumber = tonumber(countResult[1].count) + 1
    end

    -- Generate default name
    local defaultName = "Terminal #" .. terminalNumber
    local defaultModel = self.Config.TerminalSettings.default_model

    local query = string.format([[
        INSERT INTO %s (pos_x, pos_y, pos_z, ang_p, ang_y, ang_r, area_id, model, name, created_at)
        VALUES (%f, %f, %f, %f, %f, %f, %d, %s, %s, %d)
    ]], terminalsTable,
        pos.x, pos.y, pos.z,
        ang.p, ang.y, ang.r,
        areaId or 0,
        sql.SQLStr(defaultModel),
        sql.SQLStr(defaultName),
        os.time()
    )

    local result = sql.Query(query)
    if result == false then
        -- Error registering terminal
        return nil
    end

    -- Get the last inserted ID
    local idQuery = string.format("SELECT last_insert_rowid() as id")
    local idResult = sql.Query(idQuery)

    if idResult and idResult[1] then
        local terminalId = tonumber(idResult[1].id)
        self:LoadTerminals()
        return terminalId
    end

    return nil
end

-- Create a runtime terminal (not saved to database, only exists until server restart)
function ReqSystem:CreateRuntimeTerminal(pos, ang, areaId, model)
    -- Generate a runtime ID (negative to avoid conflicts with database IDs)
    self.RuntimeTerminalCounter = self.RuntimeTerminalCounter + 1
    local runtimeId = -self.RuntimeTerminalCounter

    -- Get terminal count for default name
    local terminalNumber = table.Count(self.Terminals) + 1
    local defaultName = "Terminal #" .. terminalNumber

    -- Create terminal data in memory only
    self.Terminals[runtimeId] = {
        id = runtimeId,
        pos = pos,
        ang = ang,
        area_id = areaId or 0,
        model = model or self.Config.TerminalSettings.default_model,
        name = defaultName,
        created_at = os.time(),
        is_runtime = true  -- Flag to identify runtime terminals
    }

    -- Sync to clients
    self:SyncTerminalsToClients()

    return runtimeId
end

-- Remove a runtime terminal from memory
function ReqSystem:RemoveRuntimeTerminal(terminalId)
    if self.Terminals[terminalId] and self.Terminals[terminalId].is_runtime then
        -- Remove terminal data
        self.Terminals[terminalId] = nil

        -- Remove terminal vehicle associations
        self.TerminalVehicles[terminalId] = nil

        -- Sync to clients
        self:SyncTerminalsToClients()

        net.Start("ReqSystem_SendTerminalData")
        net.WriteTable(self.TerminalVehicles)
        net.Broadcast()
    end
end

-- Update terminal configuration
function ReqSystem:UpdateTerminal(terminalId, areaId, vehicleIds, model, name)
    local terminal = self.Terminals[terminalId]
    if not terminal then return end

    -- Update in-memory terminal data
    terminal.area_id = areaId or 0
    terminal.model = model or terminal.model
    terminal.name = name or terminal.name

    -- Update vehicle associations in memory
    self.TerminalVehicles[terminalId] = {}
    if vehicleIds then
        for _, vehicleId in ipairs(vehicleIds) do
            self.TerminalVehicles[terminalId][vehicleId] = true
        end
    end

    -- If it's a saved terminal, also update the saved_terminals table
    if terminal.is_saved then
        local mapName = game.GetMap()

        -- Use default model if model is not provided or empty
        local finalModel = model
        if not finalModel or finalModel == "" then
            finalModel = self.Config.TerminalSettings.default_model
        end

        -- Update saved terminal
        local query = string.format([[
            UPDATE requisition_saved_terminals
            SET area_id = %d, model = %s, name = %s
            WHERE id = %d AND map_name = %s
        ]], areaId or 0, sql.SQLStr(finalModel), sql.SQLStr(name or ""), terminalId, sql.SQLStr(mapName))
        sql.Query(query)

        -- Clear existing vehicle assignments
        sql.Query(string.format("DELETE FROM requisition_saved_terminal_vehicles WHERE saved_terminal_id = %d", terminalId))

        -- Add new vehicle assignments
        if vehicleIds then
            for _, vehicleId in ipairs(vehicleIds) do
                local vehQuery = string.format([[
                    INSERT INTO requisition_saved_terminal_vehicles (saved_terminal_id, vehicle_id)
                    VALUES (%d, %d)
                ]], terminalId, vehicleId)
                sql.Query(vehQuery)
            end
        end
    end

    -- Sync to clients
    self:SyncTerminalsToClients()

    net.Start("ReqSystem_SendTerminalData")
    net.WriteTable(self.TerminalVehicles)
    net.Broadcast()
end

-- Delete a terminal
function ReqSystem:DeleteTerminal(terminalId)
    local terminal = self.Terminals[terminalId]

    -- Delete from saved terminals and saved terminal vehicles
    local mapName = game.GetMap()
    sql.Query(string.format("DELETE FROM requisition_saved_terminals WHERE id = %d AND map_name = %s",
        terminalId, sql.SQLStr(mapName)))
    sql.Query(string.format("DELETE FROM requisition_saved_terminal_vehicles WHERE saved_terminal_id = %d", terminalId))

    -- Remove from in-memory data
    self.Terminals[terminalId] = nil
    self.TerminalVehicles[terminalId] = nil

    -- Remove any terminal entities with this ID
    for _, ent in ipairs(ents.FindByClass("req_terminal")) do
        if IsValid(ent) and ent:GetNWInt("ReqSystem_TerminalID", 0) == terminalId then
            ent:Remove()
        end
    end

    self:SyncTerminalsToClients()
end

-- Create a new vehicle
function ReqSystem:CreateVehicle(data)
    local vehiclesTable = self.Config.Tables.vehicles
    
    local query = string.format([[
        INSERT INTO %s (name, model, class, jobs, qualifications, custom_function, key_values, created_at)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %d)
    ]], vehiclesTable,
        sql.SQLStr(data.name),
        sql.SQLStr(data.model or ""),
        sql.SQLStr(data.class),
        sql.SQLStr(util.TableToJSON(data.jobs or {})),
        sql.SQLStr(util.TableToJSON(data.qualifications or {})),
        sql.SQLStr(data.custom_function or ""),
        sql.SQLStr(util.TableToJSON(data.key_values or {})),
        os.time()
    )
    
    local result = sql.Query(query)
    if result == false then
        -- Error creating vehicle
        return false
    end
    
    self:LoadVehicles()
    self:SyncVehiclesToClients()
    return true
end

-- Update an existing vehicle
function ReqSystem:UpdateVehicle(vehicleId, data)
    local vehiclesTable = self.Config.Tables.vehicles
    
    local query = string.format([[
        UPDATE %s SET 
            name = %s,
            model = %s,
            class = %s,
            jobs = %s,
            qualifications = %s,
            custom_function = %s,
            key_values = %s
        WHERE id = %d
    ]], vehiclesTable,
        sql.SQLStr(data.name),
        sql.SQLStr(data.model or ""),
        sql.SQLStr(data.class),
        sql.SQLStr(util.TableToJSON(data.jobs or {})),
        sql.SQLStr(util.TableToJSON(data.qualifications or {})),
        sql.SQLStr(data.custom_function or ""),
        sql.SQLStr(util.TableToJSON(data.key_values or {})),
        vehicleId
    )
    
    local result = sql.Query(query)
    if result == false then
        -- Error updating vehicle
        return false
    end
    
    self:LoadVehicles()
    self:SyncVehiclesToClients()
    return true
end

-- Delete a vehicle
function ReqSystem:DeleteVehicle(vehicleId)
    local vehiclesTable = self.Config.Tables.vehicles
    local terminalVehiclesTable = self.Config.Tables.terminal_vehicles
    
    -- Delete vehicle assignments
    sql.Query(string.format("DELETE FROM %s WHERE vehicle_id = %d", terminalVehiclesTable, vehicleId))
    
    -- Delete vehicle
    sql.Query(string.format("DELETE FROM %s WHERE id = %d", vehiclesTable, vehicleId))
    
    self:LoadVehicles()
    self:LoadTerminalVehicles()
    self:SyncVehiclesToClients()
end

-- Get vehicles for a terminal
function ReqSystem:GetTerminalVehicles(terminalId)
    local vehicleList = {}
    
    if self.TerminalVehicles[terminalId] then
        for vehicleId, _ in pairs(self.TerminalVehicles[terminalId]) do
            if self.Vehicles[vehicleId] then
                table.insert(vehicleList, self.Vehicles[vehicleId])
            end
        end
    end
    
    return vehicleList
end

-- Sync data to clients
function ReqSystem:SyncAreasToClients(ply)
    net.Start("ReqSystem_SendAreas")
    net.WriteTable(self.Areas)
    if ply then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

function ReqSystem:SyncVehiclesToClients(ply)
    net.Start("ReqSystem_SendVehicles")
    net.WriteTable(self.Vehicles)
    if ply then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

function ReqSystem:SyncTerminalsToClients(ply)
    net.Start("ReqSystem_SendTerminals")
    net.WriteTable(self.Terminals)
    if ply then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

-- Initialize on server start
hook.Add("Initialize", "ReqSystem_Initialize", function()
    ReqSystem:InitializeDatabase()
    ReqSystem:LoadAreas()
    ReqSystem:LoadTerminals()
    ReqSystem:LoadVehicles()
    ReqSystem:LoadTerminalVehicles()

    -- Count saved terminals for this map
    local mapName = game.GetMap()
    local query = string.format("SELECT COUNT(*) as count FROM requisition_saved_terminals WHERE map_name = %s", sql.SQLStr(mapName))
    local result = sql.Query(query)
    local savedTerminalCount = 0
    if result and result[1] then
        savedTerminalCount = tonumber(result[1].count) or 0
    end

    -- Print startup statistics
    local vehicleCount = table.Count(ReqSystem.Vehicles)
    local areaCount = table.Count(ReqSystem.Areas)

    print(string.format("[Requisition System] Loaded: %d vehicles, %d spawn zones | Will load %d saved terminals for %s",
        vehicleCount, areaCount, savedTerminalCount, mapName))
end)

-- Send data to player on spawn
hook.Add("PlayerInitialSpawn", "ReqSystem_PlayerSpawn", function(ply)
    timer.Simple(1, function()
        if not IsValid(ply) then return end
        
        ReqSystem:SyncAreasToClients(ply)
        ReqSystem:SyncVehiclesToClients(ply)
        ReqSystem:SyncTerminalsToClients(ply)
    end)
end)

-- Network receivers
net.Receive("ReqSystem_OpenGlobalAdmin", function(len, ply)
    if not ReqSystem:IsAdmin(ply) then 
        ReqChatPrint(ply, "You don't have permission to access the admin menu!", true)
        return 
    end
    
    -- Send all data
    timer.Simple(0.1, function()
        if not IsValid(ply) then return end
        
        ReqSystem:SyncAreasToClients(ply)
        ReqSystem:SyncVehiclesToClients(ply)
        ReqSystem:SyncTerminalsToClients(ply)
        
        -- Also send terminal-vehicle relationships
        net.Start("ReqSystem_SendTerminalData")
        net.WriteTable(ReqSystem.TerminalVehicles)
        net.Send(ply)
        
        -- Tell client to open the menu
        timer.Simple(0.1, function()
            if not IsValid(ply) then return end
            net.Start("ReqSystem_OpenGlobalAdmin")
            net.Send(ply)
        end)
    end)
end)

net.Receive("ReqSystem_SaveTerminalConfig", function(len, ply)
    if not ReqSystem:IsAdmin(ply) then return end

    local terminalId = net.ReadInt(32)
    local areaId = net.ReadInt(32)
    local model = net.ReadString()
    local name = net.ReadString()
    local vehicleIds = net.ReadTable()

    ReqSystem:UpdateTerminal(terminalId, areaId, vehicleIds, model, name)
    
    -- Find and update the terminal entity model
    for _, ent in ipairs(ents.FindByClass("req_terminal")) do
        if ent:GetNWInt("ReqSystem_TerminalID", 0) == terminalId then
            ent:SetModel(model)
            ent:PhysicsInit(SOLID_VPHYSICS)
            ent:SetSolid(SOLID_VPHYSICS)
            local phys = ent:GetPhysicsObject()
            if IsValid(phys) then
                phys:EnableMotion(false)
            end
            break
        end
    end
    
    -- Notify all clients
    ReqSystem:SyncTerminalsToClients()
    
    net.Start("ReqSystem_SendTerminalData")
    net.WriteTable(ReqSystem.TerminalVehicles)
    net.Broadcast()
end)

net.Receive("ReqSystem_SaveVehicle", function(len, ply)
    if not ReqSystem:IsAdmin(ply) then return end
    
    local isEdit = net.ReadBool()
    local vehicleId = net.ReadInt(32)
    local data = net.ReadTable()
    
    if isEdit then
        ReqSystem:UpdateVehicle(vehicleId, data)
    else
        ReqSystem:CreateVehicle(data)
    end
end)

net.Receive("ReqSystem_DeleteVehicle", function(len, ply)
    if not ReqSystem:IsAdmin(ply) then return end
    
    local vehicleId = net.ReadInt(32)
    ReqSystem:DeleteVehicle(vehicleId)
end)

net.Receive("ReqSystem_DeleteTerminal", function(len, ply)
    if not ReqSystem:IsAdmin(ply) then return end
    
    local terminalId = net.ReadInt(32)
    ReqSystem:DeleteTerminal(terminalId)
end)

net.Receive("ReqSystem_DeleteArea", function(len, ply)
    if not ReqSystem:IsAdmin(ply) then return end
    
    local areaId = net.ReadInt(32)
    ReqSystem:DeleteArea(areaId)
end)

net.Receive("ReqSystem_CreateArea", function(len, ply)
    if not ReqSystem:IsAdmin(ply) then return end
    
    local name = net.ReadString()
    local minPos = net.ReadVector()
    local maxPos = net.ReadVector()
    local spawnAngle = net.ReadFloat()
    
    ReqSystem:CreateArea(name, minPos, maxPos, spawnAngle)
end)

-- Save all terminals for current map
function ReqSystem:SaveTerminalsForMap()
    local mapName = game.GetMap()

    -- Clear existing saved terminals for this map
    sql.Query(string.format("DELETE FROM requisition_saved_terminals WHERE map_name = %s", sql.SQLStr(mapName)))

    local count = 0
    local terminalEntities = ents.FindByClass("req_terminal")

    -- Save all current terminal entities
    for _, ent in ipairs(terminalEntities) do
        if IsValid(ent) then
            local terminalId = ent:GetNWInt("ReqSystem_TerminalID", 0)

            -- Check for both positive and negative IDs (runtime terminals have negative IDs)
            if terminalId ~= 0 then
                local terminal = self.Terminals[terminalId]
                if terminal then
                    -- Save terminal to saved_terminals table
                    local query = string.format([[
                        INSERT INTO requisition_saved_terminals
                        (map_name, pos_x, pos_y, pos_z, ang_p, ang_y, ang_r, area_id, model, name, created_at)
                        VALUES (%s, %f, %f, %f, %f, %f, %f, %d, %s, %s, %d)
                    ]],
                        sql.SQLStr(mapName),
                        ent:GetPos().x, ent:GetPos().y, ent:GetPos().z,
                        ent:GetAngles().p, ent:GetAngles().y, ent:GetAngles().r,
                        terminal.area_id or 0,
                        sql.SQLStr(terminal.model or self.Config.TerminalSettings.default_model),
                        sql.SQLStr(terminal.name or ""),
                        os.time()
                    )

                    sql.Query(query)

                    -- Get the ID of the newly inserted saved terminal
                    local idQuery = "SELECT last_insert_rowid() as id"
                    local idResult = sql.Query(idQuery)
                    local savedTerminalId = idResult and idResult[1] and tonumber(idResult[1].id)

                    -- Save vehicle associations for ALL terminals (not just runtime)
                    if savedTerminalId and self.TerminalVehicles[terminalId] then
                        -- Save vehicle associations to saved_terminal_vehicles table
                        for vehicleId, _ in pairs(self.TerminalVehicles[terminalId]) do
                            local vehQuery = string.format([[
                                INSERT INTO requisition_saved_terminal_vehicles
                                (saved_terminal_id, vehicle_id)
                                VALUES (%d, %d)
                            ]], savedTerminalId, vehicleId)
                            sql.Query(vehQuery)
                        end
                    end

                    count = count + 1
                end
            end
        end
    end

    return count
end

-- Load saved terminals for current map
function ReqSystem:LoadSavedTerminals()
    local mapName = game.GetMap()

    local query = string.format("SELECT * FROM requisition_saved_terminals WHERE map_name = %s", sql.SQLStr(mapName))
    local results = sql.Query(query)

    if not results then return 0 end

    local count = 0
    for _, row in ipairs(results) do
        local pos = Vector(tonumber(row.pos_x), tonumber(row.pos_y), tonumber(row.pos_z))
        local ang = Angle(tonumber(row.ang_p), tonumber(row.ang_y), tonumber(row.ang_r))
        local model = row.model or self.Config.TerminalSettings.default_model
        local name = row.name or ""
        local areaId = tonumber(row.area_id) or 0
        local savedTerminalId = tonumber(row.id)

        -- Create a unique terminal ID using the saved terminal ID
        -- Use positive IDs to mark these as "saved" terminals
        local terminalId = savedTerminalId

        -- Create terminal data in memory (not in database - it's already in saved_terminals)
        self.Terminals[terminalId] = {
            id = terminalId,
            pos = pos,
            ang = ang,
            area_id = areaId,
            model = model,
            name = name,
            created_at = tonumber(row.created_at) or os.time(),
            is_saved = true  -- Flag to identify saved terminals
        }

        -- Load vehicle associations
        local vehQuery = string.format("SELECT vehicle_id FROM requisition_saved_terminal_vehicles WHERE saved_terminal_id = %d", savedTerminalId)
        local vehResults = sql.Query(vehQuery)

        if vehResults then
            self.TerminalVehicles[terminalId] = {}
            for _, vehRow in ipairs(vehResults) do
                local vehicleId = tonumber(vehRow.vehicle_id)
                self.TerminalVehicles[terminalId][vehicleId] = true
            end
        end

        -- Spawn the terminal entity
        local terminal = ents.Create("req_terminal")
        if IsValid(terminal) then
            terminal:SetPos(pos)
            terminal:SetAngles(ang)

            -- Mark as auto-loaded to use the saved ID and model
            terminal.ReqSystem_IsAutoLoaded = true
            terminal.ReqSystem_LoadedID = terminalId
            terminal.ReqSystem_LoadedModel = model

            terminal:Spawn()
            terminal:Activate()

            -- Set the terminal ID
            timer.Simple(0.1, function()
                if IsValid(terminal) then
                    terminal:SetNWInt("ReqSystem_TerminalID", terminalId)
                end
            end)

            count = count + 1
        end
    end

    -- Sync to clients after loading all terminals
    if count > 0 then
        self:SyncTerminalsToClients()
    end

    return count
end

-- Network receiver for save command
net.Receive("ReqSystem_SaveTerminals", function(len, ply)
    if not ReqSystem:IsAdmin(ply) then 
        ReqChatPrint(ply, "You don't have permission!", true)
        return 
    end
    
    local count = ReqSystem:SaveTerminalsForMap()
    ReqChatPrint(ply, string.format("Saved %d terminals for map: %s", count, game.GetMap()))
    
    -- Broadcast to all admins
    for _, admin in ipairs(player.GetAll()) do
        if ReqSystem:IsAdmin(admin) and admin ~= ply then
            ReqChatPrint(admin, string.format("%s saved %d terminals", ply:Nick(), count))
        end
    end
end)

-- Cache model for LVS/Simfphys vehicles
function ReqSystem:CacheVehicleModel(vehicleId, class)
    -- Spawn entity temporarily to get model
    local tempEnt = ents.Create(class)
    if not IsValid(tempEnt) then return nil end
    
    tempEnt:SetPos(Vector(0, 0, -10000)) -- Spawn far away
    tempEnt:Spawn()
    
    local model = tempEnt:GetModel()
    tempEnt:Remove()
    
    if model and model ~= "" and model ~= "models/error.mdl" then
        -- Update vehicle in database with model
        local vehiclesTable = self.Config.Tables.vehicles
        local query = string.format("UPDATE %s SET model = %s WHERE id = %d",
            vehiclesTable, sql.SQLStr(model), vehicleId)
        sql.Query(query)
        
        return model
    end
    
    return nil
end

-- Cache models for all vehicles with empty model field
function ReqSystem:CacheAllVehicleModels()
    local cached = 0
    
    for id, veh in pairs(self.Vehicles) do
        if not veh.model or veh.model == "" then
            local model = self:CacheVehicleModel(id, veh.class)
            if model then
                veh.model = model
                cached = cached + 1
            end
        end
    end
    
    if cached > 0 then
        -- Reload vehicles to get updated models
        self:LoadVehicles()
        self:SyncVehiclesToClients()
    end
    
    return cached
end

-- Auto-load saved terminals on map start
hook.Add("InitPostEntity", "ReqSystem_LoadSavedTerminals", function()
    -- Cache vehicle models first
    timer.Simple(1, function()
        local cached = ReqSystem:CacheAllVehicleModels()
    end)

    -- Then load saved terminals
    timer.Simple(2, function()
        ReqSystem:LoadSavedTerminals()
    end)
end)

-- Wipe all requisition system data
function ReqSystem:WipeDatabase()
    local areasTable = self.Config.Tables.areas
    local terminalsTable = self.Config.Tables.terminals
    local vehiclesTable = self.Config.Tables.vehicles
    local terminalVehiclesTable = self.Config.Tables.terminal_vehicles
    
    -- Delete all data
    sql.Query(string.format("DELETE FROM %s", terminalVehiclesTable))
    sql.Query(string.format("DELETE FROM %s", vehiclesTable))
    sql.Query(string.format("DELETE FROM %s", terminalsTable))
    sql.Query(string.format("DELETE FROM %s", areasTable))
    sql.Query("DELETE FROM requisition_saved_terminals")
    
    -- Remove all terminal entities
    for _, ent in ipairs(ents.FindByClass("req_terminal")) do
        if IsValid(ent) then
            ent:Remove()
        end
    end
    
    -- Reload data
    self:LoadAreas()
    self:LoadTerminals()
    self:LoadVehicles()
    self:LoadTerminalVehicles()
    
    -- Sync to all clients
    self:SyncAreasToClients()
    self:SyncVehiclesToClients()
    self:SyncTerminalsToClients()
    
    -- Database wiped
end

-- Console command to wipe database
concommand.Add("reqsystem_wipe", function(ply, cmd, args)
    if IsValid(ply) then
        ReqChatPrint(ply, "This command can only be run from the server console!", true)
        return
    end
    
    print("[Requisition System] WARNING: About to wipe all requisition system data!")
    print("[Requisition System] This will delete all vehicles, terminals, areas, and saved terminals!")
    print("[Requisition System] Type 'reqsystem_wipe_confirm' to confirm.")
end)

-- Confirmation command
concommand.Add("reqsystem_wipe_confirm", function(ply, cmd, args)
    if IsValid(ply) then
        ReqChatPrint(ply, "This command can only be run from the server console!", true)
        return
    end
    
    print("[Requisition System] Wiping database...")
    ReqSystem:WipeDatabase()
end)

-- Console command to cache vehicle models
concommand.Add("reqsystem_cache_models", function(ply, cmd, args)
    if IsValid(ply) and not ReqSystem:IsAdmin(ply) then
        ReqChatPrint(ply, "You don't have permission!", true)
        return
    end
    
    local msg = "Caching vehicle models..."
    if IsValid(ply) then
        ReqChatPrint(ply, msg)
    else
        print("[Requisition System] " .. msg)
    end
    
    timer.Simple(0.1, function()
        local cached = ReqSystem:CacheAllVehicleModels()
        local result = string.format("Cached %d vehicle models", cached)
        
        if IsValid(ply) then
            ReqChatPrint(ply, result)
        else
            print("[Requisition System] " .. result)
        end
    end)
end)

-- Server-side database loaded
