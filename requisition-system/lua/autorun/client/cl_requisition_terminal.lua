-- Client-side terminal UI

ReqSystem.Areas = ReqSystem.Areas or {}
ReqSystem.Vehicles = ReqSystem.Vehicles or {}
ReqSystem.Terminals = ReqSystem.Terminals or {}
ReqSystem.TerminalVehicles = ReqSystem.TerminalVehicles or {}

-- Network receivers
net.Receive("ReqSystem_SendAreas", function()
    ReqSystem.Areas = net.ReadTable()
end)

net.Receive("ReqSystem_SendVehicles", function()
    ReqSystem.Vehicles = net.ReadTable()
end)

net.Receive("ReqSystem_SendTerminals", function()
    ReqSystem.Terminals = net.ReadTable()
end)

net.Receive("ReqSystem_SendTerminalData", function()
    ReqSystem.TerminalVehicles = net.ReadTable()
end)

-- Open terminal UI
net.Receive("ReqSystem_OpenTerminal", function()
    local terminalId = net.ReadInt(32)
    local areaName = net.ReadString()
    local vehicles = net.ReadTable()
    
    ReqSystem:OpenTerminalUI(terminalId, areaName, vehicles)
end)

-- Terminal UI
function ReqSystem:OpenTerminalUI(terminalId, areaName, vehicles)
    -- Create main frame
    local frame = vgui.Create("DFrame")
    frame:SetSize(700, 600)
    frame:Center()
    frame:SetTitle("")
    frame:SetVisible(true)
    frame:SetDraggable(true)
    frame:ShowCloseButton(false)
    frame:MakePopup()
    
    frame.Paint = function(self, w, h)
        -- Main background with gradient
        surface.SetDrawColor(25, 25, 30, 250)
        draw.RoundedBox(8, 0, 0, w, h, Color(25, 25, 30, 250))
        
        -- Header bar with gradient
        surface.SetDrawColor(35, 100, 180, 255)
        draw.RoundedBoxEx(8, 0, 0, w, 40, Color(35, 100, 180, 255), true, true, false, false)
        draw.RoundedBox(0, 0, 35, w, 5, Color(45, 120, 200, 255))
        
        -- Title text
        draw.SimpleText("Vehicle Requisition Terminal", "DermaLarge", 15, 12, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
        -- Outer glow
        surface.SetDrawColor(0, 0, 0, 100)
        draw.RoundedBox(8, -2, -2, w + 4, h + 4, Color(0, 0, 0, 0))
    end
    
    -- Return Vehicle button (in header bar)
    local returnBtn = vgui.Create("DButton", frame)
    returnBtn:SetSize(150, 30)
    returnBtn:SetPos(frame:GetWide() - 190, 5)
    returnBtn:SetText("")
    
    -- Cache for vehicle checking (refresh every 0.5 seconds instead of every frame)
    local cachedVehicles = {}
    local lastCheck = 0
    
    -- Get player's vehicles in this spawn area
    local function GetPlayerVehiclesInArea()
        -- Return cached result if recent
        if CurTime() - lastCheck < 0.5 then
            return cachedVehicles
        end
        
        local ply = LocalPlayer()
        local vehicles = {}
        local areaId = 0
        
        -- Find area ID from terminal
        if ReqSystem.Terminals and ReqSystem.Terminals[terminalId] then
            areaId = ReqSystem.Terminals[terminalId].area_id
        end
        
        if areaId == 0 then return vehicles end
        
        local area = ReqSystem.Areas[areaId]
        if not area then return vehicles end
        
        -- Check all vehicles (only check X/Y, ignore Z axis since vehicles may be on ground)
        for _, ent in ipairs(ents.GetAll()) do
            -- Check both standard vehicles and LVS/Simfphys vehicles
            local isVehicle = ent:IsVehicle() or 
                              string.match(ent:GetClass(), "^lvs_") or 
                              string.match(ent:GetClass(), "^sim_fphys_")
            
            if IsValid(ent) and isVehicle then
                local owner = ent:GetNWString("ReqSystem_Owner", "")
                local vehAreaId = ent:GetNWInt("ReqSystem_SpawnAreaID", 0)
                
                -- Check if owned by player and from this area
                if owner == ply:SteamID() and vehAreaId == areaId then
                    local vehPos = ent:GetPos()
                    
                    -- Normalize bounds
                    local minX = math.min(area.min_pos.x, area.max_pos.x)
                    local maxX = math.max(area.min_pos.x, area.max_pos.x)
                    local minY = math.min(area.min_pos.y, area.max_pos.y)
                    local maxY = math.max(area.min_pos.y, area.max_pos.y)
                    
                    -- Check if in spawn area (X and Y only, ignore Z)
                    if vehPos.x >= minX and vehPos.x <= maxX and
                       vehPos.y >= minY and vehPos.y <= maxY then
                        table.insert(vehicles, ent)
                    end
                end
            end
        end
        
        cachedVehicles = vehicles
        lastCheck = CurTime()
        return vehicles
    end
    
    returnBtn.Paint = function(self, w, h)
        local playerVehicles = GetPlayerVehiclesInArea()
        local hasVehicles = #playerVehicles > 0
        
        local col = Color(200, 80, 50, 220)
        if not hasVehicles then
            col = Color(70, 70, 80, 180)
        elseif self:IsHovered() then
            col = Color(220, 100, 60, 255)
        end
        draw.RoundedBox(4, 0, 0, w, h, col)
        
        if hasVehicles then
            draw.SimpleText("Return Vehicle", "DermaDefaultBold", w/2, h/2 - 6, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("(" .. #playerVehicles .. ")", "DermaDefault", w/2, h/2 + 8, Color(255, 255, 255, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        else
            draw.SimpleText("Return Vehicle", "DermaDefaultBold", w/2, h/2, Color(180, 180, 180, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
    
    returnBtn.DoClick = function()
        local playerVehicles = GetPlayerVehiclesInArea()
        
        if #playerVehicles == 0 then
            notification.AddLegacy("No vehicles in spawn area to return", NOTIFY_ERROR, 3)
            surface.PlaySound("buttons/button10.wav")
            return
        end
        
        -- If only one vehicle, return it immediately
        if #playerVehicles == 1 then
            net.Start("ReqSystem_ReturnVehicle")
            net.WriteEntity(playerVehicles[1])
            net.SendToServer()
            
            notification.AddLegacy("Returning vehicle...", NOTIFY_HINT, 2)
            surface.PlaySound("buttons/button15.wav")
            
            timer.Simple(0.2, function()
                if IsValid(frame) then
                    frame:Close()
                end
            end)
            return
        end
        
        -- Multiple vehicles - show selection menu
        local selectMenu = DermaMenu()
        selectMenu:SetMinimumWidth(200)
        
        for i, veh in ipairs(playerVehicles) do
            local option = selectMenu:AddOption("Vehicle #" .. i, function()
                net.Start("ReqSystem_ReturnVehicle")
                net.WriteEntity(veh)
                net.SendToServer()
                
                notification.AddLegacy("Returning vehicle...", NOTIFY_HINT, 2)
                surface.PlaySound("buttons/button15.wav")
                
                timer.Simple(0.2, function()
                    if IsValid(frame) then
                        frame:Close()
                    end
                end)
            end)
        end
        
        selectMenu:Open()
    end
    
    -- Custom close button
    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetSize(30, 30)
    closeBtn:SetPos(frame:GetWide() - 35, 5)
    closeBtn:SetText("")
    closeBtn.Paint = function(self, w, h)
        local col = Color(180, 50, 50, 200)
        if self:IsHovered() then
            col = Color(220, 60, 60, 255)
        end
        draw.RoundedBox(4, 0, 0, w, h, col)
        draw.SimpleText("✕", "DermaLarge", w/2, h/2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    closeBtn.DoClick = function()
        frame:Close()
    end
    
    -- Area info panel
    local infoPanel = vgui.Create("DPanel", frame)
    infoPanel:Dock(TOP)
    infoPanel:SetTall(50)
    infoPanel:DockMargin(10, 50, 10, 5)
    infoPanel.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(35, 35, 40, 220))
        surface.SetDrawColor(50, 50, 60, 100)
        surface.DrawOutlinedRect(0, 0, w, h)
        
        -- Area name
        draw.SimpleText("Spawn Area: " .. areaName, "DermaDefaultBold", 10, h/2, Color(100, 200, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    -- Vehicles scroll panel
    local vehiclePanel = vgui.Create("DPanel", frame)
    vehiclePanel:Dock(FILL)
    vehiclePanel:DockMargin(10, 5, 10, 10)
    vehiclePanel.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(35, 35, 40, 220))
        surface.SetDrawColor(50, 50, 60, 100)
        surface.DrawOutlinedRect(0, 0, w, h)
    end
    
    local vehicleScroll = vgui.Create("DScrollPanel", vehiclePanel)
    vehicleScroll:Dock(FILL)
    vehicleScroll:DockMargin(5, 5, 5, 5)
    
    local vehicleList = vgui.Create("DPanel", vehicleScroll)
    vehicleList:Dock(TOP)
    vehicleList:SetTall(0)
    vehicleList.Paint = function(self, w, h) end
    
    -- Populate vehicles
    local y = 0
    for _, vehicle in ipairs(vehicles) do
        local canSpawn, reason = self:PlayerCanSpawnVehicle(LocalPlayer(), vehicle)
        
        local vehicleCard = vgui.Create("DPanel", vehicleList)
        vehicleCard:SetPos(0, y)
        vehicleCard:SetSize(660, 120)
        
        vehicleCard.Paint = function(self, w, h)
            local col = Color(45, 45, 50, 200)
            if self:IsHovered() then
                col = Color(55, 55, 65, 230)
            end
            draw.RoundedBox(4, 0, 0, w, h, col)
            
            -- Left accent bar
            if canSpawn then
                draw.RoundedBox(0, 0, 0, 4, h, Color(50, 200, 100, 255))
            else
                draw.RoundedBox(0, 0, 0, 4, h, Color(200, 50, 50, 255))
            end
        end
        
        -- Vehicle name
        local nameLabel = vgui.Create("DLabel", vehicleCard)
        nameLabel:SetPos(15, 10)
        nameLabel:SetText(vehicle.name)
        nameLabel:SetFont("DermaLarge")
        nameLabel:SetTextColor(Color(255, 255, 255, 255))
        nameLabel:SizeToContents()
        
        -- Requirements
        local reqY = 40
        if vehicle.jobs and #vehicle.jobs > 0 then
            local jobLabel = vgui.Create("DLabel", vehicleCard)
            jobLabel:SetPos(15, reqY)
            jobLabel:SetText("Required Jobs: " .. table.concat(vehicle.jobs, ", "))
            jobLabel:SetFont("DermaDefault")
            jobLabel:SetTextColor(Color(200, 200, 220, 255))
            jobLabel:SizeToContents()
            reqY = reqY + 20
        end
        
        if vehicle.qualifications and #vehicle.qualifications > 0 then
            local qualLabel = vgui.Create("DLabel", vehicleCard)
            qualLabel:SetPos(15, reqY)
            qualLabel:SetText("Required Qualifications: " .. table.concat(vehicle.qualifications, ", "))
            qualLabel:SetFont("DermaDefault")
            qualLabel:SetTextColor(Color(200, 200, 220, 255))
            qualLabel:SizeToContents()
        end
        
        -- Spawn button
        local spawnBtn = vgui.Create("DButton", vehicleCard)
        spawnBtn:SetPos(660 - 120, 10)
        spawnBtn:SetSize(100, 100)
        spawnBtn:SetText("")
        spawnBtn:SetEnabled(canSpawn)
        
        spawnBtn.Paint = function(self, w, h)
            local col = Color(40, 120, 200, 220)
            if not canSpawn then
                col = Color(80, 80, 80, 180)
            elseif self:IsHovered() then
                col = Color(50, 140, 220, 255)
            end
            draw.RoundedBox(4, 0, 0, w, h, col)
            
            if canSpawn then
                draw.SimpleText("Spawn", "DermaLarge", w/2, h/2 - 10, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText("Vehicle", "DermaDefault", w/2, h/2 + 10, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else
                draw.SimpleText("Locked", "DermaDefaultBold", w/2, h/2 - 10, Color(200, 200, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText(reason or "N/A", "DermaDefault", w/2, h/2 + 10, Color(180, 180, 180, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
        
        spawnBtn.DoClick = function()
            -- Request vehicle spawn
            net.Start("ReqSystem_SpawnVehicle")
            net.WriteInt(terminalId, 32)
            net.WriteInt(vehicle.id, 32)
            net.SendToServer()
            
            frame:Close()
        end
        
        y = y + 125
    end
    
    vehicleList:SetTall(math.max(y, 10))
    
    -- Show message if no vehicles
    if #vehicles == 0 then
        local noVehicles = vgui.Create("DLabel", vehicleList)
        noVehicles:SetPos(0, 0)
        noVehicles:SetSize(660, 100)
        noVehicles:SetText("No vehicles available at this terminal.\nContact an administrator.")
        noVehicles:SetFont("DermaLarge")
        noVehicles:SetTextColor(Color(200, 200, 200, 255))
        noVehicles:SetContentAlignment(5)
    end
end

-- Handle spawn response
net.Receive("ReqSystem_SpawnVehicle", function()
    local success = net.ReadBool()
    local message = net.ReadString()
    
    -- Visual feedback could be added here
    -- For now, server sends chat message
end)

-- Chat command to open admin menu
hook.Add("OnPlayerChat", "ReqSystem_AdminCommand", function(ply, text)
    if ply ~= LocalPlayer() then return end
    if text == ReqSystem.Config.AdminCommand then
        net.Start("ReqSystem_OpenGlobalAdmin")
        net.SendToServer()
        return true
    end
    if text == "!reqsave" then
        net.Start("ReqSystem_SaveTerminals")
        net.SendToServer()
        return true
    end
end)

-- Client-side terminal UI loaded
