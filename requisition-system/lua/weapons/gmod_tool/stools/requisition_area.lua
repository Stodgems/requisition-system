-- Requisition Area Creation Tool

TOOL.Category = "Requisition System"
TOOL.Name = "Spawn Area Creator"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar["corner1_x"] = "0"
TOOL.ClientConVar["corner1_y"] = "0"
TOOL.ClientConVar["corner1_z"] = "0"
TOOL.ClientConVar["corner2_x"] = "0"
TOOL.ClientConVar["corner2_y"] = "0"
TOOL.ClientConVar["corner2_z"] = "0"
TOOL.ClientConVar["spawn_angle"] = "0"

if CLIENT then
    language.Add("tool.requisition_area.name", "Spawn Area Creator")
    language.Add("tool.requisition_area.desc", "Create spawn areas for requisition terminals")
    language.Add("tool.requisition_area.left", "Set first corner")
    language.Add("tool.requisition_area.right", "Set second corner")
    language.Add("tool.requisition_area.reload", "Clear selection")
end

function TOOL:LeftClick(trace)
    if CLIENT then return true end
    
    local ply = self:GetOwner()
    if not ReqSystem:IsAdmin(ply) then
        ply:ChatPrint("[Requisition] You must be an admin to use this tool!")
        return false
    end
    
    -- Set first corner at ground level (add 5 units above to ensure it's above ground)
    local pos = trace.HitPos + Vector(0, 0, 5)
    self:GetOwner():SetNWVector("ReqArea_Corner1", pos)
    
    -- Calculate spawn angle from player's view direction and snap to 15 degree increments
    local rawAng = ply:EyeAngles().y
    local ang = math.Round(rawAng / 15) * 15
    self:GetOwner():SetNWFloat("ReqArea_SpawnAngle", ang)
    
    self:GetOwner():ChatPrint("[Requisition] First corner set at " .. ReqSystem:FormatPosition(pos))
    self:GetOwner():ChatPrint("[Requisition] Spawn direction: " .. ang .. "° (snapped from " .. math.Round(rawAng) .. "°)")
    
    -- Check if both corners are set
    local corner2 = self:GetOwner():GetNWVector("ReqArea_Corner2", Vector(0, 0, 0))
    if corner2 ~= Vector(0, 0, 0) then
        self:PromptAreaName(ply)
    end
    
    return true
end

function TOOL:RightClick(trace)
    if CLIENT then return true end
    
    local ply = self:GetOwner()
    if not ReqSystem:IsAdmin(ply) then
        ply:ChatPrint("[Requisition] You must be an admin to use this tool!")
        return false
    end
    
    -- Set second corner with height (150 units above ground for vehicles)
    local pos = trace.HitPos + Vector(0, 0, 150)
    self:GetOwner():SetNWVector("ReqArea_Corner2", pos)
    self:GetOwner():ChatPrint("[Requisition] Second corner set at " .. ReqSystem:FormatPosition(pos))
    
    -- Check if both corners are set
    local corner1 = self:GetOwner():GetNWVector("ReqArea_Corner1", Vector(0, 0, 0))
    if corner1 ~= Vector(0, 0, 0) then
        self:PromptAreaName(ply)
    end
    
    return true
end

function TOOL:Reload(trace)
    if CLIENT then return true end
    
    local ply = self:GetOwner()
    if not ReqSystem:IsAdmin(ply) then return false end
    
    -- Clear corners
    self:GetOwner():SetNWVector("ReqArea_Corner1", Vector(0, 0, 0))
    self:GetOwner():SetNWVector("ReqArea_Corner2", Vector(0, 0, 0))
    self:GetOwner():SetNWFloat("ReqArea_SpawnAngle", 0)
    self:GetOwner():ChatPrint("[Requisition] Selection cleared")
    
    return true
end

function TOOL:PromptAreaName(ply)
    if not SERVER then return end
    
    local corner1 = ply:GetNWVector("ReqArea_Corner1", Vector(0, 0, 0))
    local corner2 = ply:GetNWVector("ReqArea_Corner2", Vector(0, 0, 0))
    
    if corner1 == Vector(0, 0, 0) or corner2 == Vector(0, 0, 0) then return end
    
    -- Open text entry dialog on client
    local spawnAngle = ply:GetNWFloat("ReqArea_SpawnAngle", 0)
    net.Start("ReqSystem_PromptAreaName")
    net.WriteVector(corner1)
    net.WriteVector(corner2)
    net.WriteFloat(spawnAngle)
    net.Send(ply)
end

function TOOL:Think()
    -- Visual feedback for selected corners
end

function TOOL:DrawHUD()
    local ply = LocalPlayer()
    local corner1 = ply:GetNWVector("ReqArea_Corner1", Vector(0, 0, 0))
    local corner2 = ply:GetNWVector("ReqArea_Corner2", Vector(0, 0, 0))
    
    -- Draw instructions
    local y = ScrH() / 2 + 100
    draw.SimpleText("Requisition Area Creator", "DermaLarge", ScrW() / 2, y, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    y = y + 30
    
    draw.SimpleText("Left Click: Set first corner", "DermaDefault", ScrW() / 2, y, Color(200, 200, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    y = y + 20
    draw.SimpleText("Right Click: Set second corner", "DermaDefault", ScrW() / 2, y, Color(200, 200, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    y = y + 20
    draw.SimpleText("Reload: Clear selection", "DermaDefault", ScrW() / 2, y, Color(200, 200, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    
    -- Show selected corners
    y = y + 40
    if corner1 != Vector(0, 0, 0) then
        draw.SimpleText("Corner 1: " .. ReqSystem:FormatPosition(corner1), "DermaDefaultBold", ScrW() / 2, y, Color(100, 255, 100, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        y = y + 20
    end
    
    if corner2 != Vector(0, 0, 0) then
        draw.SimpleText("Corner 2: " .. ReqSystem:FormatPosition(corner2), "DermaDefaultBold", ScrW() / 2, y, Color(100, 255, 100, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
end

function TOOL:DrawToolScreen()
    return true
end

-- Build control panel
function TOOL.BuildCPanel(panel)
    panel:Help("Create spawn areas for vehicle requisition terminals.")
    panel:Help("Left Click: Set first corner")
    panel:Help("Right Click: Set second corner")
    panel:Help("Reload: Clear selection")
    
    panel:Help("")
    panel:Help("Existing Spawn Areas:")
    
    -- Create a list of spawn areas
    local areaList = vgui.Create("DListView")
    areaList:SetMultiSelect(false)
    areaList:AddColumn("Area Name")
    areaList:AddColumn("ID")
    areaList:SetTall(200)
    
    -- Populate with areas
    if ReqSystem and ReqSystem.Areas then
        for id, area in pairs(ReqSystem.Areas) do
            areaList:AddLine(area.name, id)
        end
    end
    
    panel:AddItem(areaList)
    
    -- Store reference to BuildCPanel for use in callbacks
    local rebuildPanel = function()
        if not IsValid(panel) then return end
        
        local wep = LocalPlayer():GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() == "gmod_tool" then
            local mode = wep:GetToolObject("requisition_area")
            if mode and mode.BuildCPanel then
                panel:Clear()
                mode.BuildCPanel(panel)
            end
        end
    end
    
    -- Delete button
    local deleteBtn = vgui.Create("DButton")
    deleteBtn:SetText("Delete Selected Area")
    deleteBtn:SetTall(25)
    deleteBtn.DoClick = function()
        local selected = areaList:GetSelectedLine()
        if not selected then
            notification.AddLegacy("No area selected!", NOTIFY_ERROR, 3)
            surface.PlaySound("buttons/button10.wav")
            return
        end
        
        local line = areaList:GetLine(selected)
        local areaName = line:GetColumnText(1)
        local areaId = tonumber(line:GetColumnText(2))
        
        Derma_Query(
            "Delete spawn area '" .. areaName .. "'?\nThis cannot be undone!",
            "Confirm Delete",
            "Yes",
            function()
                net.Start("ReqSystem_DeleteArea")
                net.WriteInt(areaId, 32)
                net.SendToServer()
                
                notification.AddLegacy("Deleted area: " .. areaName, NOTIFY_GENERIC, 3)
                surface.PlaySound("buttons/button14.wav")
                
                -- Refresh list after a moment
                timer.Simple(0.3, rebuildPanel)
            end,
            "No"
        )
    end
    panel:AddItem(deleteBtn)
    
    -- Refresh button
    local refreshBtn = vgui.Create("DButton")
    refreshBtn:SetText("Refresh List")
    refreshBtn:SetTall(25)
    refreshBtn.DoClick = function()
        rebuildPanel()
        notification.AddLegacy("List refreshed", NOTIFY_GENERIC, 2)
    end
    panel:AddItem(refreshBtn)
    
    -- Visualize button
    local visualizeBtn = vgui.Create("DButton")
    visualizeBtn:SetText("Visualize Selected Area (10s)")
    visualizeBtn:SetTall(25)
    visualizeBtn.DoClick = function()
        local selected = areaList:GetSelectedLine()
        if not selected then
            notification.AddLegacy("No area selected!", NOTIFY_ERROR, 3)
            surface.PlaySound("buttons/button10.wav")
            return
        end
        
        local line = areaList:GetLine(selected)
        local areaId = tonumber(line:GetColumnText(2))
        
        if ReqSystem and ReqSystem.Areas and ReqSystem.Areas[areaId] then
            local area = ReqSystem.Areas[areaId]
            
            -- Store for visualization
            LocalPlayer().ReqVisualizingArea = area
            LocalPlayer().ReqVisualizeEnd = CurTime() + 10
            
            notification.AddLegacy("Visualizing: " .. area.name, NOTIFY_HINT, 3)
            surface.PlaySound("buttons/button15.wav")
        end
    end
    panel:AddItem(visualizeBtn)
end

if CLIENT then
    -- Network receiver for area name prompt
    net.Receive("ReqSystem_PromptAreaName", function()
        local corner1 = net.ReadVector()
        local corner2 = net.ReadVector()
        local spawnAngle = net.ReadFloat()
        
        Derma_StringRequest(
            "Name Spawn Area",
            "Enter a name for this spawn area:",
            "",
            function(text)
                if text and text ~= "" then
                    -- Send area creation to server
                    net.Start("ReqSystem_CreateArea")
                    net.WriteString(text)
                    net.WriteVector(corner1)
                    net.WriteVector(corner2)
                    net.WriteFloat(spawnAngle)
                    net.SendToServer()
                    
                    -- Clear corners
                    LocalPlayer():SetNWVector("ReqArea_Corner1", Vector(0, 0, 0))
                    LocalPlayer():SetNWVector("ReqArea_Corner2", Vector(0, 0, 0))
                    LocalPlayer():SetNWFloat("ReqArea_SpawnAngle", 0)
                    
                    LocalPlayer():ChatPrint("[Requisition] Spawn area '" .. text .. "' created!")
                    
                    -- Refresh toolgun panel after a moment
                    timer.Simple(0.5, function()
                        local panel = controlpanel.Get("requisition_area")
                        if not IsValid(panel) then return end
                        
                        local wep = LocalPlayer():GetActiveWeapon()
                        if IsValid(wep) and wep:GetClass() == "gmod_tool" then
                            local mode = wep:GetToolObject("requisition_area")
                            if mode and mode.BuildCPanel then
                                panel:ClearControls()
                                mode.BuildCPanel(panel)
                            end
                        end
                    end)
                end
            end,
            function() end
        )
    end)
    
    -- Hook to refresh panel when areas are synced from server
    local lastAreaCount = 0
    hook.Add("Think", "ReqSystem_RefreshToolgunPanel", function()
        if not ReqSystem or not ReqSystem.Areas then return end
        
        local currentCount = table.Count(ReqSystem.Areas)
        if currentCount ~= lastAreaCount then
            lastAreaCount = currentCount
            
            -- Check if the toolgun panel exists and is the requisition area tool
            local panel = controlpanel.Get("requisition_area")
            if IsValid(panel) and GetConVar("gmod_toolmode"):GetString() == "requisition_area" then
                -- Rebuild the panel using the weapon's tool mode
                local wep = LocalPlayer():GetActiveWeapon()
                if IsValid(wep) and wep:GetClass() == "gmod_tool" then
                    local mode = wep:GetToolObject("requisition_area")
                    if mode and mode.BuildCPanel then
                        panel:ClearControls()
                        mode.BuildCPanel(panel)
                    end
                end
            end
        end
    end)
end

if SERVER then
    util.AddNetworkString("ReqSystem_PromptAreaName")
end

-- Draw area bounds
hook.Add("PostDrawTranslucentRenderables", "ReqSystem_DrawAreaBounds", function()
    local ply = LocalPlayer()
    
    -- Draw area being visualized from control panel
    if ply.ReqVisualizingArea and ply.ReqVisualizeEnd and CurTime() < ply.ReqVisualizeEnd then
        local area = ply.ReqVisualizingArea
        local minPos = area.min_pos
        local maxPos = area.max_pos
        
        -- Pulsing effect
        local pulse = math.abs(math.sin(CurTime() * 3)) * 0.5 + 0.5
        local col = Color(255, 100, 100, 150 + pulse * 100)
        
        -- Draw wireframe box
        render.DrawWireframeBox(Vector(0, 0, 0), Angle(0, 0, 0), minPos, maxPos, col, true)
        
        -- Draw corner spheres
        render.DrawWireframeSphere(minPos, 20, 12, 12, col, true)
        render.DrawWireframeSphere(maxPos, 20, 12, 12, col, true)
        
        -- Draw text label
        local center = (minPos + maxPos) / 2
        local ang = (ply:EyePos() - center):Angle()
        ang:RotateAroundAxis(ang:Forward(), 90)
        ang:RotateAroundAxis(ang:Right(), 90)
        
        cam.Start3D2D(center + Vector(0, 0, 50), Angle(0, ang.y, 90), 0.5)
            draw.SimpleTextOutlined(area.name, "DermaLarge", 0, 0, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0, 255))
            local timeLeft = math.ceil(ply.ReqVisualizeEnd - CurTime())
            draw.SimpleTextOutlined(timeLeft .. "s", "DermaDefault", 0, 25, Color(200, 200, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 255))
        cam.End3D2D()
    end
    
    -- Only draw tool selection if tool is active
    if not LocalPlayer():GetActiveWeapon():IsValid() then return end
    if LocalPlayer():GetActiveWeapon():GetClass() ~= "gmod_tool" then return end
    if GetConVar("gmod_toolmode"):GetString() ~= "requisition_area" then return end
    
    local corner1 = ply:GetNWVector("ReqArea_Corner1", Vector(0, 0, 0))
    local corner2 = ply:GetNWVector("ReqArea_Corner2", Vector(0, 0, 0))
    
    -- Draw corner markers
    if corner1 != Vector(0, 0, 0) then
        render.DrawWireframeSphere(corner1, 10, 8, 8, Color(100, 255, 100, 255), true)
    end
    
    if corner2 != Vector(0, 0, 0) then
        render.DrawWireframeSphere(corner2, 10, 8, 8, Color(100, 255, 100, 255), true)
    end
    
    -- Draw box if both corners set
    if corner1 != Vector(0, 0, 0) and corner2 != Vector(0, 0, 0) then
        local minPos = Vector(
            math.min(corner1.x, corner2.x),
            math.min(corner1.y, corner2.y),
            math.min(corner1.z, corner2.z)
        )
        
        local maxPos = Vector(
            math.max(corner1.x, corner2.x),
            math.max(corner1.y, corner2.y),
            math.max(corner1.z, corner2.z)
        )
        
        -- Draw wireframe box
        render.DrawWireframeBox(Vector(0, 0, 0), Angle(0, 0, 0), minPos, maxPos, Color(100, 200, 255, 150), true)
        
        -- Draw arrow showing spawn direction
        local spawnAngle = ply:GetNWFloat("ReqArea_SpawnAngle", 0)
        local center = (minPos + maxPos) / 2
        local arrowLength = 100
        local arrowWidth = 30
        
        -- Calculate arrow direction
        local forward = Angle(0, spawnAngle, 0):Forward()
        local arrowEnd = center + forward * arrowLength
        
        -- Draw arrow shaft
        render.DrawLine(center, arrowEnd, Color(255, 100, 100, 255), true)
        
        -- Draw arrow head (3 lines forming arrow tip)
        local right = Angle(0, spawnAngle, 0):Right()
        local headBack = arrowEnd - forward * 30
        render.DrawLine(arrowEnd, headBack + right * arrowWidth, Color(255, 100, 100, 255), true)
        render.DrawLine(arrowEnd, headBack - right * arrowWidth, Color(255, 100, 100, 255), true)
        render.DrawLine(headBack + right * arrowWidth, headBack - right * arrowWidth, Color(255, 100, 100, 255), true)
    end
end)
