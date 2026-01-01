-- Client-side admin menu UI

-- Open global admin menu
net.Receive("ReqSystem_OpenGlobalAdmin", function()
    ReqSystem:OpenGlobalAdminMenu()
end)

-- Open terminal admin menu
net.Receive("ReqSystem_OpenTerminalAdmin", function()
    local terminalId = net.ReadInt(32)
    ReqSystem:OpenTerminalAdminMenu(terminalId)
end)

-- Global admin menu with tabs
function ReqSystem:OpenGlobalAdminMenu()
    -- Create main frame
    local frame = vgui.Create("DFrame")
    frame:SetSize(900, 700)
    frame:Center()
    frame:SetTitle("")
    frame:SetVisible(true)
    frame:SetDraggable(true)
    frame:ShowCloseButton(false)
    frame:MakePopup()
    
    frame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(25, 25, 30, 250))
        draw.RoundedBoxEx(8, 0, 0, w, 40, Color(35, 100, 180, 255), true, true, false, false)
        draw.RoundedBox(0, 0, 35, w, 5, Color(45, 120, 200, 255))
        draw.SimpleText("Requisition System - Admin Panel", "DermaLarge", 15, 12, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    
    -- Close button
    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetSize(30, 30)
    closeBtn:SetPos(frame:GetWide() - 35, 5)
    closeBtn:SetText("")
    closeBtn.Paint = function(self, w, h)
        local col = Color(180, 50, 50, 200)
        if self:IsHovered() then col = Color(220, 60, 60, 255) end
        draw.RoundedBox(4, 0, 0, w, h, col)
        draw.SimpleText("✕", "DermaLarge", w/2, h/2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    closeBtn.DoClick = function() frame:Close() end
    
    -- Tab control
    local tabs = vgui.Create("DPropertySheet", frame)
    tabs:Dock(FILL)
    tabs:DockMargin(10, 50, 10, 10)
    
    -- Vehicles tab
    local vehiclesPanel = vgui.Create("DPanel")
    vehiclesPanel.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(35, 35, 40, 220))
    end
    tabs:AddSheet("Vehicles", vehiclesPanel, "icon16/car.png")
    self:PopulateVehiclesTab(vehiclesPanel, frame)
    
    -- Terminals tab
    local terminalsPanel = vgui.Create("DPanel")
    terminalsPanel.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(35, 35, 40, 220))
    end
    tabs:AddSheet("Terminals", terminalsPanel, "icon16/computer.png")
    self:PopulateTerminalsTab(terminalsPanel, frame)
    
    -- Areas tab
    local areasPanel = vgui.Create("DPanel")
    areasPanel.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(35, 35, 40, 220))
    end
    tabs:AddSheet("Spawn Areas", areasPanel, "icon16/map.png")
    self:PopulateAreasTab(areasPanel, frame)
end

-- Populate Vehicles Tab
function ReqSystem:PopulateVehiclesTab(panel, parentFrame)
    -- Add vehicle button
    local addBtn = vgui.Create("DButton", panel)
    addBtn:Dock(TOP)
    addBtn:SetHeight(40)
    addBtn:DockMargin(5, 5, 5, 5)
    addBtn:SetText("")
    addBtn.Paint = function(self, w, h)
        local col = Color(40, 120, 200, 220)
        if self:IsHovered() then col = Color(50, 140, 220, 255) end
        draw.RoundedBox(4, 0, 0, w, h, col)
        draw.SimpleText("+ Add New Vehicle", "DermaDefaultBold", w/2, h/2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    addBtn.DoClick = function()
        self:OpenVehicleEditor(parentFrame, nil)
    end
    
    -- Vehicle list
    local scroll = vgui.Create("DScrollPanel", panel)
    scroll:Dock(FILL)
    scroll:DockMargin(5, 0, 5, 5)
    
    local list = vgui.Create("DPanel", scroll)
    list:Dock(TOP)
    list:SetTall(0)
    list.Paint = function(self, w, h) end
    
    local y = 0
    for id, vehicle in pairs(self.Vehicles) do
        local card = vgui.Create("DPanel", list)
        card:SetPos(0, y)
        card:SetSize(860, 80)
        card.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(45, 45, 50, 200))
            draw.RoundedBox(0, 0, 0, 4, h, Color(50, 150, 220, 255))
        end
        
        local nameLabel = vgui.Create("DLabel", card)
        nameLabel:SetPos(15, 10)
        nameLabel:SetText(vehicle.name)
        nameLabel:SetFont("DermaDefaultBold")
        nameLabel:SetTextColor(Color(255, 255, 255, 255))
        nameLabel:SizeToContents()
        
        local classLabel = vgui.Create("DLabel", card)
        classLabel:SetPos(15, 30)
        classLabel:SetText("Class: " .. vehicle.class)
        classLabel:SetFont("DermaDefault")
        classLabel:SetTextColor(Color(180, 180, 200, 255))
        classLabel:SizeToContents()
        
        local editBtn = vgui.Create("DButton", card)
        editBtn:SetPos(860 - 220, 10)
        editBtn:SetSize(100, 60)
        editBtn:SetText("")
        editBtn.Paint = function(self, w, h)
            local col = Color(40, 120, 200, 220)
            if self:IsHovered() then col = Color(50, 140, 220, 255) end
            draw.RoundedBox(4, 0, 0, w, h, col)
            draw.SimpleText("Edit", "DermaDefaultBold", w/2, h/2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        editBtn.DoClick = function()
            self:OpenVehicleEditor(parentFrame, id)
        end
        
        local deleteBtn = vgui.Create("DButton", card)
        deleteBtn:SetPos(860 - 110, 10)
        deleteBtn:SetSize(100, 60)
        deleteBtn:SetText("")
        deleteBtn.Paint = function(self, w, h)
            local col = Color(180, 50, 50, 200)
            if self:IsHovered() then col = Color(220, 60, 60, 255) end
            draw.RoundedBox(4, 0, 0, w, h, col)
            draw.SimpleText("Delete", "DermaDefaultBold", w/2, h/2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        deleteBtn.DoClick = function()
            Derma_Query("Delete vehicle '" .. vehicle.name .. "'?", "Confirm", "Yes", function()
                net.Start("ReqSystem_DeleteVehicle")
                net.WriteInt(id, 32)
                net.SendToServer()
                timer.Simple(0.3, function()
                    if IsValid(parentFrame) then
                        parentFrame:Close()
                        self:OpenGlobalAdminMenu()
                    end
                end)
            end, "No")
        end
        
        y = y + 85
    end
    
    list:SetTall(math.max(y, 10))
end

-- Populate Terminals Tab
function ReqSystem:PopulateTerminalsTab(panel, parentFrame)
    local infoLabel = vgui.Create("DLabel", panel)
    infoLabel:Dock(TOP)
    infoLabel:SetHeight(30)
    infoLabel:DockMargin(5, 5, 5, 5)
    infoLabel:SetText("Total Terminals: " .. table.Count(self.Terminals))
    infoLabel:SetFont("DermaDefaultBold")
    infoLabel:SetTextColor(Color(200, 220, 255, 255))
    
    local scroll = vgui.Create("DScrollPanel", panel)
    scroll:Dock(FILL)
    scroll:DockMargin(5, 0, 5, 5)
    
    local list = vgui.Create("DPanel", scroll)
    list:Dock(TOP)
    list:SetTall(0)
    list.Paint = function(self, w, h) end
    
    local y = 0
    for id, terminal in pairs(self.Terminals) do
        local area = self.Areas[terminal.area_id]
        
        local card = vgui.Create("DPanel", list)
        card:SetPos(0, y)
        card:SetSize(860, 80)
        card.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(45, 45, 50, 200))
            draw.RoundedBox(0, 0, 0, 4, h, Color(50, 150, 220, 255))
        end
        
        local idLabel = vgui.Create("DLabel", card)
        idLabel:SetPos(15, 10)
        local displayName = terminal.name and terminal.name ~= "" and terminal.name or ("Terminal #" .. id)
        idLabel:SetText(displayName)
        idLabel:SetFont("DermaDefaultBold")
        idLabel:SetTextColor(Color(255, 255, 255, 255))
        idLabel:SizeToContents()
        
        local posLabel = vgui.Create("DLabel", card)
        posLabel:SetPos(15, 30)
        posLabel:SetText("Position: " .. self:FormatPosition(terminal.pos))
        posLabel:SetFont("DermaDefault")
        posLabel:SetTextColor(Color(180, 180, 200, 255))
        posLabel:SizeToContents()
        
        local areaLabel = vgui.Create("DLabel", card)
        areaLabel:SetPos(15, 50)
        areaLabel:SetText("Area: " .. (area and area.name or "None"))
        areaLabel:SetFont("DermaDefault")
        areaLabel:SetTextColor(Color(180, 180, 200, 255))
        areaLabel:SizeToContents()

        local editBtn = vgui.Create("DButton", card)
        editBtn:SetPos(860 - 330, 10)
        editBtn:SetSize(100, 60)
        editBtn:SetText("")
        editBtn.Paint = function(self, w, h)
            local col = Color(40, 120, 200, 220)
            if self:IsHovered() then col = Color(50, 140, 220, 255) end
            draw.RoundedBox(4, 0, 0, w, h, col)
            draw.SimpleText("Edit", "DermaDefaultBold", w/2, h/2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        editBtn.DoClick = function()
            self:OpenTerminalAdminMenu(id)
        end
        
        local deleteBtn = vgui.Create("DButton", card)
        deleteBtn:SetPos(860 - 220, 10)
        deleteBtn:SetSize(100, 60)
        deleteBtn:SetText("")
        deleteBtn.Paint = function(self, w, h)
            local col = Color(180, 50, 50, 200)
            if self:IsHovered() then col = Color(220, 60, 60, 255) end
            draw.RoundedBox(4, 0, 0, w, h, col)
            draw.SimpleText("Delete", "DermaDefaultBold", w/2, h/2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        deleteBtn.DoClick = function()
            Derma_Query("Delete terminal #" .. id .. "?", "Confirm", "Yes", function()
                net.Start("ReqSystem_DeleteTerminal")
                net.WriteInt(id, 32)
                net.SendToServer()
                timer.Simple(0.3, function()
                    if IsValid(parentFrame) then
                        parentFrame:Close()
                        self:OpenGlobalAdminMenu()
                    end
                end)
            end, "No")
        end
        
        y = y + 85
    end
    
    list:SetTall(math.max(y, 10))
end

-- Populate Areas Tab
function ReqSystem:PopulateAreasTab(panel, parentFrame)
    local infoLabel = vgui.Create("DLabel", panel)
    infoLabel:Dock(TOP)
    infoLabel:SetHeight(30)
    infoLabel:DockMargin(5, 5, 5, 5)
    infoLabel:SetText("Use the 'Spawn Area Creator' tool to create new areas")
    infoLabel:SetFont("DermaDefault")
    infoLabel:SetTextColor(Color(200, 220, 255, 255))
    
    local scroll = vgui.Create("DScrollPanel", panel)
    scroll:Dock(FILL)
    scroll:DockMargin(5, 0, 5, 5)
    
    local list = vgui.Create("DPanel", scroll)
    list:Dock(TOP)
    list:SetTall(0)
    list.Paint = function(self, w, h) end
    
    local y = 0
    for id, area in pairs(self.Areas) do
        local card = vgui.Create("DPanel", list)
        card:SetPos(0, y)
        card:SetSize(860, 100)
        card.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(45, 45, 50, 200))
            draw.RoundedBox(0, 0, 0, 4, h, Color(50, 150, 220, 255))
        end
        
        local nameLabel = vgui.Create("DLabel", card)
        nameLabel:SetPos(15, 10)
        nameLabel:SetText(area.name)
        nameLabel:SetFont("DermaDefaultBold")
        nameLabel:SetTextColor(Color(255, 255, 255, 255))
        nameLabel:SizeToContents()
        
        local minLabel = vgui.Create("DLabel", card)
        minLabel:SetPos(15, 35)
        minLabel:SetText("Min: " .. self:FormatPosition(area.min_pos))
        minLabel:SetFont("DermaDefault")
        minLabel:SetTextColor(Color(180, 180, 200, 255))
        minLabel:SizeToContents()
        
        local maxLabel = vgui.Create("DLabel", card)
        maxLabel:SetPos(15, 55)
        maxLabel:SetText("Max: " .. self:FormatPosition(area.max_pos))
        maxLabel:SetFont("DermaDefault")
        maxLabel:SetTextColor(Color(180, 180, 200, 255))
        maxLabel:SizeToContents()
        
        local deleteBtn = vgui.Create("DButton", card)
        deleteBtn:SetPos(860 - 110, 20)
        deleteBtn:SetSize(100, 60)
        deleteBtn:SetText("")
        deleteBtn.Paint = function(self, w, h)
            local col = Color(180, 50, 50, 200)
            if self:IsHovered() then col = Color(220, 60, 60, 255) end
            draw.RoundedBox(4, 0, 0, w, h, col)
            draw.SimpleText("Delete", "DermaDefaultBold", w/2, h/2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        deleteBtn.DoClick = function()
            Derma_Query("Delete area '" .. area.name .. "'?", "Confirm", "Yes", function()
                net.Start("ReqSystem_DeleteArea")
                net.WriteInt(id, 32)
                net.SendToServer()
                timer.Simple(0.3, function()
                    if IsValid(parentFrame) then
                        parentFrame:Close()
                        self:OpenGlobalAdminMenu()
                    end
                end)
            end, "No")
        end
        
        y = y + 105
    end
    
    list:SetTall(math.max(y, 10))
end

-- Vehicle Editor
function ReqSystem:OpenVehicleEditor(parent, vehicleId)
    local isEdit = vehicleId ~= nil
    local vehicleData = isEdit and self.Vehicles[vehicleId] or {}
    
    local frame = vgui.Create("DFrame")
    frame:SetSize(600, 600)
    frame:Center()
    frame:SetTitle("")
    frame:SetVisible(true)
    frame:SetDraggable(true)
    frame:ShowCloseButton(false)
    frame:MakePopup()
    
    frame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(25, 25, 30, 250))
        draw.RoundedBoxEx(8, 0, 0, w, 40, Color(35, 100, 180, 255), true, true, false, false)
        draw.RoundedBox(0, 0, 35, w, 5, Color(45, 120, 200, 255))
        local title = isEdit and "Edit Vehicle" or "Add New Vehicle"
        draw.SimpleText(title, "DermaLarge", 15, 10, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    
    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetSize(30, 30)
    closeBtn:SetPos(frame:GetWide() - 35, 5)
    closeBtn:SetText("")
    closeBtn.Paint = function(self, w, h)
        local col = Color(180, 50, 50, 200)
        if self:IsHovered() then col = Color(220, 60, 60, 255) end
        draw.RoundedBox(4, 0, 0, w, h, col)
        draw.SimpleText("✕", "DermaLarge", w/2, h/2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    closeBtn.DoClick = function() frame:Close() end
    
    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(10, 50, 10, 10)
    
    local y = 0
    
    -- Vehicle Name
    local nameLabel = vgui.Create("DLabel", scroll)
    nameLabel:SetPos(0, y)
    nameLabel:SetText("Vehicle Name (Display Name):")
    nameLabel:SizeToContents()
    y = y + 20
    
    local nameEntry = vgui.Create("DTextEntry", scroll)
    nameEntry:SetPos(0, y)
    nameEntry:SetSize(560, 25)
    nameEntry:SetValue(vehicleData.name or "")
    y = y + 35
    
    -- Vehicle Class dropdown
    local classLabel = vgui.Create("DLabel", scroll)
    classLabel:SetPos(0, y)
    classLabel:SetText("Entity Class (Vehicle):")
    classLabel:SizeToContents()
    y = y + 20
    
    local classCombo = vgui.Create("DComboBox", scroll)
    classCombo:SetPos(0, y)
    classCombo:SetSize(560, 25)
    classCombo:SetValue(vehicleData.class or "Select Vehicle Class")
    
    -- Get vehicles from spawn menu and scripted entities
    local vehicleList = {}
    local vehicleNameMap = {}  -- Map spawn key to display name
    local displayNameToKey = {}  -- Map display name to spawn key (for lookup)
    local spawnMenuVehicles = list.Get("Vehicles")
    
    if spawnMenuVehicles then
        for spawnMenuKey, data in pairs(spawnMenuVehicles) do
            -- Vehicle structure loaded
            
            -- Use the PrintName from the list.Get data which should already have it
            local displayName = data.PrintName or data.Name or spawnMenuKey
            
            -- The actual entity class to spawn (e.g., prop_vehicle_jeep)
            local entityClass = data.Class or spawnMenuKey
            
            -- Store the mapping using spawn menu key
            vehicleNameMap[spawnMenuKey] = displayName
            displayNameToKey[displayName] = spawnMenuKey
            
            table.insert(vehicleList, {
                spawnMenuKey = spawnMenuKey,  -- Keep for reference
                class = entityClass,          -- Actual entity class to spawn
                name = displayName,
                model = data.Model or "",
                keyValues = data.KeyValues    -- Store KeyValues for vehicle script
            })
        end
    end
    
    -- Check SpawnableEntities for LVS vehicles (they register here, not in Vehicles list)
    local spawnableEnts = list.Get("SpawnableEntities")
    local lvsCount = 0
    
    if spawnableEnts then
        for className, data in pairs(spawnableEnts) do
            
            -- Add LVS and Simfphys vehicles from spawnable entities
            -- Exclude items, tools, and accessories (only add actual vehicles)
            local isVehicle = (string.StartWith(className, "lvs_") or string.StartWith(className, "simfphys_")) and
                             not string.find(className, "_item_") and
                             not string.find(className, "_vehicle_repair") and
                             not string.find(className, "_vehicle_spammer") and
                             not string.find(className, "_vehicle_air_refil") and
                             not string.find(className, "_missile") and
                             not string.find(className, "_torpedo") and
                             not string.find(className, "_trailer_") and
                             data.PrintName
            
            if isVehicle then
                
                -- Check if already added
                local alreadyAdded = false
                for _, veh in ipairs(vehicleList) do
                    if veh.class == className then
                        alreadyAdded = true
                        break
                    end
                end
                
                if not alreadyAdded then
                    local displayName = data.PrintName or className
                    vehicleNameMap[className] = displayName
                    displayNameToKey[displayName] = className
                    
                    table.insert(vehicleList, {
                        spawnMenuKey = className,
                        class = className,
                        name = displayName,
                        model = data.Model or "",
                        keyValues = {}  -- LVS/Simfphys don't use KeyValues
                    })
                    
                    lvsCount = lvsCount + 1
                end
            end
        end
    end
    
    -- Sort by name
    table.sort(vehicleList, function(a, b) return a.name < b.name end)
    
    for _, veh in ipairs(vehicleList) do
        -- Pass spawn menu key as data, not the entity class
        classCombo:AddChoice(veh.name, veh.spawnMenuKey)
    end
    
    -- Always update display name when vehicle class is selected
    classCombo.OnSelect = function(self, index, displayName, className)
        -- Use the display name from our map
        if className and vehicleNameMap[className] then
            nameEntry:SetValue(vehicleNameMap[className])
        else
            nameEntry:SetValue(displayName)
        end
    end
    
    -- Set initial value for edit mode
    if isEdit and vehicleData.class then
        for _, veh in ipairs(vehicleList) do
            if veh.class == vehicleData.class then
                classCombo:SetValue(veh.name)
                break
            end
        end
    end
    
    y = y + 35
    
    -- Jobs - Multi-select panel
    local jobsLabel = vgui.Create("DLabel", scroll)
    jobsLabel:SetPos(0, y)
    jobsLabel:SetText("Allowed Jobs (leave all unchecked for all jobs):")
    jobsLabel:SizeToContents()
    y = y + 20
    
    local jobsPanel = vgui.Create("DPanel", scroll)
    jobsPanel:SetPos(0, y)
    jobsPanel:SetSize(560, 120)
    jobsPanel.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(35, 35, 40, 220))
        surface.SetDrawColor(50, 50, 60, 100)
        surface.DrawOutlinedRect(0, 0, w, h)
    end
    
    local jobsScroll = vgui.Create("DScrollPanel", jobsPanel)
    jobsScroll:Dock(FILL)
    jobsScroll:DockMargin(5, 5, 5, 5)
    
    local selectedJobs = {}
    if vehicleData.jobs then
        for _, job in ipairs(vehicleData.jobs) do
            selectedJobs[job] = true
        end
    end
    
    -- Get all teams/jobs
    local teams = {}
    for i = 0, 255 do
        if team.Valid(i) then
            local teamName = team.GetName(i)
            if teamName and teamName ~= "" then
                table.insert(teams, {
                    name = teamName,
                    color = team.GetColor(i)
                })
            end
        end
    end
    
    for _, teamData in ipairs(teams) do
        local jobCheck = vgui.Create("DCheckBoxLabel", jobsScroll)
        jobCheck:Dock(TOP)
        jobCheck:SetText(teamData.name)
        jobCheck:SetValue(selectedJobs[teamData.name] or false)
        jobCheck:DockMargin(2, 2, 2, 2)
        jobCheck:SetTextColor(teamData.color)
        jobCheck.jobName = teamData.name
    end
    
    y = y + 130
    
    -- Qualifications - Multi-select panel
    local qualsLabel = vgui.Create("DLabel", scroll)
    qualsLabel:SetPos(0, y)
    qualsLabel:SetText("Required Qualifications (leave all unchecked for none):")
    qualsLabel:SizeToContents()
    y = y + 20
    
    local qualsPanel = vgui.Create("DPanel", scroll)
    qualsPanel:SetPos(0, y)
    qualsPanel:SetSize(560, 120)
    qualsPanel.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(35, 35, 40, 220))
        surface.SetDrawColor(50, 50, 60, 100)
        surface.DrawOutlinedRect(0, 0, w, h)
    end
    
    local qualsScroll = vgui.Create("DScrollPanel", qualsPanel)
    qualsScroll:Dock(FILL)
    qualsScroll:DockMargin(5, 5, 5, 5)
    
    local selectedQuals = {}
    if vehicleData.qualifications then
        for _, qual in ipairs(vehicleData.qualifications) do
            selectedQuals[qual] = true
        end
    end
    
    -- Get all qualifications from QualSystem
    if QualSystem and QualSystem.Qualifications then
        for qualName, qualData in pairs(QualSystem.Qualifications) do
            local qualCheck = vgui.Create("DCheckBoxLabel", qualsScroll)
            qualCheck:Dock(TOP)
            qualCheck:SetText(qualData.display_name or qualName)
            qualCheck:SetValue(selectedQuals[qualName] or false)
            qualCheck:DockMargin(2, 2, 2, 2)
            qualCheck:SetTextColor(Color(100, 200, 255, 255))
            qualCheck.qualName = qualName
        end
    else
        local noQuals = vgui.Create("DLabel", qualsScroll)
        noQuals:Dock(TOP)
        noQuals:SetText("No qualifications available (Qualification System not loaded)")
        noQuals:SetTextColor(Color(200, 200, 200, 255))
    end
    
    y = y + 130
    
    -- Custom Function
    local funcLabel = vgui.Create("DLabel", scroll)
    funcLabel:SetPos(0, y)
    funcLabel:SetText("Custom Spawn Function (Lua):")
    funcLabel:SizeToContents()
    y = y + 20
    
    local funcEntry = vgui.Create("DTextEntry", scroll)
    funcEntry:SetPos(0, y)
    funcEntry:SetSize(560, 100)
    funcEntry:SetMultiline(true)
    funcEntry:SetValue(vehicleData.custom_function or "")
    y = y + 110
    
    -- Save button
    local saveBtn = vgui.Create("DButton", scroll)
    saveBtn:SetPos(0, y)
    saveBtn:SetSize(560, 40)
    saveBtn:SetText("")
    saveBtn.Paint = function(self, w, h)
        local col = Color(50, 180, 100, 220)
        if self:IsHovered() then col = Color(60, 200, 120, 255) end
        draw.RoundedBox(6, 0, 0, w, h, col)
        draw.SimpleText(isEdit and "Update Vehicle" or "Create Vehicle", "DermaLarge", w/2, h/2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    saveBtn.DoClick = function()
        -- Get the spawn menu key from the combo box's selected data
        local _, _, spawnMenuKey = classCombo:GetSelected()
        
        -- Fallback to GetValue if GetSelected doesn't work
        if not spawnMenuKey or spawnMenuKey == "" then
            local displayName = classCombo:GetValue()
            -- Try to convert display name to spawn key
            spawnMenuKey = displayNameToKey[displayName] or displayName
        end
        
        -- Find the vehicle data from our list
        local selectedVehicle = nil
        for _, veh in ipairs(vehicleList) do
            if veh.spawnMenuKey == spawnMenuKey then
                selectedVehicle = veh
                break
            end
        end
        
        if not selectedVehicle then
            Derma_Message("Please select a vehicle from the dropdown!", "Error", "OK")
            return
        end
        
        local vehicleInfo = {
            name = nameEntry:GetValue(),
            model = selectedVehicle.model or "",
            class = selectedVehicle.class,  -- Actual entity class (e.g., prop_vehicle_jeep)
            spawn_key = spawnMenuKey,  -- Spawn menu key for reference
            key_values = selectedVehicle.keyValues or {},  -- Vehicle script data
            jobs = {},
            qualifications = {},
            custom_function = funcEntry:GetValue()
        }
        
        -- Collect selected jobs from checkboxes
        for _, child in ipairs(jobsScroll:GetChildren()) do
            if child.jobName and child:GetChecked() then
                table.insert(vehicleInfo.jobs, child.jobName)
            end
        end
        
        -- Collect selected qualifications from checkboxes
        for _, child in ipairs(qualsScroll:GetChildren()) do
            if child.qualName and child:GetChecked() then
                table.insert(vehicleInfo.qualifications, child.qualName)
            end
        end
        
        -- Validate - check that we have a name
        if vehicleInfo.name == "" then
            Derma_Message("Please enter a vehicle name!", "Error", "OK")
            return
        end
        
        -- Send to server
        net.Start("ReqSystem_SaveVehicle")
        net.WriteBool(isEdit)
        net.WriteInt(vehicleId or 0, 32)
        net.WriteTable(vehicleInfo)
        net.SendToServer()
        
        frame:Close()
        timer.Simple(0.3, function()
            if IsValid(parent) then
                parent:Close()
                ReqSystem:OpenGlobalAdminMenu()
            end
        end)
    end
end

-- Terminal Admin Menu
function ReqSystem:OpenTerminalAdminMenu(terminalId)
    local terminal = self.Terminals[terminalId]
    if not terminal then return end
    
    local frame = vgui.Create("DFrame")
    frame:SetSize(600, 500)
    frame:Center()
    frame:SetTitle("")
    frame:SetVisible(true)
    frame:SetDraggable(true)
    frame:ShowCloseButton(false)
    frame:MakePopup()
    
    frame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(25, 25, 30, 250))
        draw.RoundedBoxEx(8, 0, 0, w, 40, Color(35, 100, 180, 255), true, true, false, false)
        draw.RoundedBox(0, 0, 35, w, 5, Color(45, 120, 200, 255))
        local displayName = terminal.name and terminal.name ~= "" and terminal.name or ("Terminal #" .. terminalId)
        draw.SimpleText("Terminal Configuration: " .. displayName, "DermaLarge", 15, 10, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetSize(30, 30)
    closeBtn:SetPos(frame:GetWide() - 35, 5)
    closeBtn:SetText("")
    closeBtn.Paint = function(self, w, h)
        local col = Color(180, 50, 50, 200)
        if self:IsHovered() then col = Color(220, 60, 60, 255) end
        draw.RoundedBox(4, 0, 0, w, h, col)
        draw.SimpleText("✕", "DermaLarge", w/2, h/2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    closeBtn.DoClick = function() frame:Close() end

    local content = vgui.Create("DPanel", frame)
    content:Dock(FILL)
    content:DockMargin(10, 50, 10, 10)
    content.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(35, 35, 40, 220))
    end

    -- Terminal name
    local nameLabel = vgui.Create("DLabel", content)
    nameLabel:Dock(TOP)
    nameLabel:SetHeight(25)
    nameLabel:DockMargin(10, 10, 10, 5)
    nameLabel:SetText("Terminal Name:")
    nameLabel:SetFont("DermaDefaultBold")
    nameLabel:SetTextColor(Color(200, 220, 255, 255))

    local nameEntry = vgui.Create("DTextEntry", content)
    nameEntry:Dock(TOP)
    nameEntry:SetHeight(30)
    nameEntry:DockMargin(10, 0, 10, 10)
    nameEntry:SetValue(terminal.name or "")
    nameEntry:SetPlaceholderText("e.g., Main Garage Terminal")

    -- Area selector
    local areaLabel = vgui.Create("DLabel", content)
    areaLabel:Dock(TOP)
    areaLabel:SetHeight(25)
    areaLabel:DockMargin(10, 10, 10, 5)
    areaLabel:SetText("Spawn Area:")
    areaLabel:SetFont("DermaDefaultBold")
    areaLabel:SetTextColor(Color(200, 220, 255, 255))
    
    local areaDropdown = vgui.Create("DComboBox", content)
    areaDropdown:Dock(TOP)
    areaDropdown:SetHeight(30)
    areaDropdown:DockMargin(10, 0, 10, 10)
    areaDropdown:SetValue("Select Area")
    
    local selectedAreaId = terminal.area_id
    for id, area in pairs(self.Areas) do
        areaDropdown:AddChoice(area.name, id)
        if id == terminal.area_id then
            areaDropdown:SetValue(area.name)
        end
    end
    
    areaDropdown.OnSelect = function(self, index, value, data)
        selectedAreaId = data
    end
    
    -- Model selector
    local modelLabel = vgui.Create("DLabel", content)
    modelLabel:Dock(TOP)
    modelLabel:SetHeight(25)
    modelLabel:DockMargin(10, 10, 10, 5)
    modelLabel:SetText("Terminal Model:")
    modelLabel:SetFont("DermaDefaultBold")
    modelLabel:SetTextColor(Color(200, 220, 255, 255))
    
    local modelEntry = vgui.Create("DTextEntry", content)
    modelEntry:Dock(TOP)
    modelEntry:SetHeight(30)
    modelEntry:DockMargin(10, 0, 10, 10)
    modelEntry:SetValue(terminal.model or ReqSystem.Config.TerminalSettings.default_model)
    modelEntry:SetPlaceholderText("e.g., models/props_combine/combine_interface001.mdl")
    
    -- Vehicle list
    local vehicleLabel = vgui.Create("DLabel", content)
    vehicleLabel:Dock(TOP)
    vehicleLabel:SetHeight(25)
    vehicleLabel:DockMargin(10, 10, 10, 5)
    vehicleLabel:SetText("Available Vehicles:")
    vehicleLabel:SetFont("DermaDefaultBold")
    vehicleLabel:SetTextColor(Color(200, 220, 255, 255))
    
    local vehicleScroll = vgui.Create("DScrollPanel", content)
    vehicleScroll:Dock(FILL)
    vehicleScroll:DockMargin(10, 0, 10, 10)
    
    local selectedVehicles = {}
    if self.TerminalVehicles[terminalId] then
        for vehId, _ in pairs(self.TerminalVehicles[terminalId]) do
            selectedVehicles[vehId] = true
        end
    end
    
    for id, vehicle in pairs(self.Vehicles) do
        local check = vgui.Create("DCheckBoxLabel", vehicleScroll)
        check:Dock(TOP)
        check:SetText(vehicle.name)
        check:SetValue(selectedVehicles[id] or false)
        check:DockMargin(5, 2, 5, 2)
        check:SetTextColor(Color(255, 255, 255, 255))
        check.vehicleId = id
    end
    
    -- Save button
    local saveBtn = vgui.Create("DButton", content)
    saveBtn:Dock(BOTTOM)
    saveBtn:SetHeight(40)
    saveBtn:DockMargin(10, 5, 10, 10)
    saveBtn:SetText("")
    saveBtn.Paint = function(self, w, h)
        local col = Color(50, 180, 100, 220)
        if self:IsHovered() then col = Color(60, 200, 120, 255) end
        draw.RoundedBox(6, 0, 0, w, h, col)
        draw.SimpleText("Save Configuration", "DermaLarge", w/2, h/2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    saveBtn.DoClick = function()
        local vehicleIds = {}

        -- Get the canvas (inner panel) of the scroll panel
        local canvas = vehicleScroll:GetCanvas()
        if IsValid(canvas) then
            for _, child in ipairs(canvas:GetChildren()) do
                if child.vehicleId and child:GetChecked() then
                    table.insert(vehicleIds, child.vehicleId)
                end
            end
        end

        local model = modelEntry:GetValue()
        if model == "" then
            model = ReqSystem.Config.TerminalSettings.default_model
        end

        local name = nameEntry:GetValue()

        net.Start("ReqSystem_SaveTerminalConfig")
        net.WriteInt(terminalId, 32)
        net.WriteInt(selectedAreaId or 0, 32)
        net.WriteString(model)
        net.WriteString(name)
        net.WriteTable(vehicleIds)
        net.SendToServer()

        frame:Close()
    end
end

-- Client-side admin menu loaded
