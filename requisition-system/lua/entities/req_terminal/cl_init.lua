-- Client-side terminal entity

include("shared.lua")

function ENT:Initialize()
    self.LastThink = 0
end

function ENT:Draw()
    self:DrawModel()
    
    -- Get config settings
    local config = ReqSystem and ReqSystem.Config and ReqSystem.Config.TerminalSettings
    if not config then return end
    
    local displayName = config.display_name or "Requisition Terminal"
    local heightOffset = config.text_height_offset or 60
    local showTerminalId = config.show_terminal_id
    local showUseHint = config.show_use_hint
    
    -- Draw terminal info above entity
    local terminalId = self:GetNWInt("ReqSystem_TerminalID", 0)
    
    local pos = self:GetPos() + Vector(0, 0, heightOffset)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)
    
    cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.1)
        -- Main title
        draw.SimpleTextOutlined(displayName, "DermaLarge", 0, -30, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0, 255))
        
        -- Terminal ID (optional)
        if showTerminalId and terminalId > 0 then
            draw.SimpleTextOutlined("ID: " .. terminalId, "DermaDefault", 0, 0, Color(200, 220, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 255))
        end
        
        -- Use hint (optional)
        if showUseHint then
            local hintY = showTerminalId and 20 or 0
            draw.SimpleTextOutlined("Press E to use", "DermaDefault", 0, hintY, Color(150, 200, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 255))
        end
    cam.End3D2D()
end

function ENT:Think()
    -- Optional: Add ambient effects or animations
    self.LastThink = CurTime()
end
