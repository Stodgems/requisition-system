-- Server-side terminal entity

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    -- Use default model from config
    local defaultModel = ReqSystem.Config.TerminalSettings.default_model
    self:SetModel(defaultModel)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:EnableMotion(false)
    end
    
    -- Register terminal in database
    self:SetNWInt("ReqSystem_TerminalID", 0)
    self:SetNWInt("ReqSystem_AreaID", 0)
    
    timer.Simple(0.1, function()
        if IsValid(self) then
            -- Check if this is an auto-loaded terminal
            if self.ReqSystem_IsAutoLoaded and self.ReqSystem_LoadedID then
                -- Don't register a new terminal, just use the existing ID
                self:SetNWInt("ReqSystem_TerminalID", self.ReqSystem_LoadedID)
            else
                -- Register as a new terminal
                local terminalId = ReqSystem:RegisterTerminal(self:GetPos(), self:GetAngles(), 0, defaultModel)
                if terminalId then
                    self:SetNWInt("ReqSystem_TerminalID", terminalId)
                    -- Load saved model if different
                    local terminal = ReqSystem.Terminals[terminalId]
                    if terminal and terminal.model and terminal.model ~= "" then
                        self:SetModel(terminal.model)
                        self:PhysicsInit(SOLID_VPHYSICS)
                        self:SetSolid(SOLID_VPHYSICS)
                        local phys = self:GetPhysicsObject()
                        if IsValid(phys) then
                            phys:EnableMotion(false)
                        end
                    end
                end
            end
        end
    end)
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    
    local terminalId = self:GetNWInt("ReqSystem_TerminalID", 0)
    if terminalId == 0 then return end
    
    -- Get terminal data
    local terminal = ReqSystem.Terminals[terminalId]
    if not terminal then return end
    
    -- Get area
    local area = ReqSystem.Areas[terminal.area_id]
    
    -- Get available vehicles
    local vehicles = ReqSystem:GetTerminalVehicles(terminalId)
    
    -- Send data to client
    net.Start("ReqSystem_OpenTerminal")
    net.WriteInt(terminalId, 32)
    net.WriteString(area and area.name or "No Area Assigned")
    net.WriteTable(vehicles)
    net.Send(activator)
end

function ENT:OnRemove()
    -- Don't delete the database entry if this is an auto-loaded terminal
    -- (it will be reloaded on next map start)
    if self.ReqSystem_IsAutoLoaded then
        return
    end
    
    local terminalId = self:GetNWInt("ReqSystem_TerminalID", 0)
    if terminalId > 0 then
        ReqSystem:DeleteTerminal(terminalId)
    end
end

-- Override OnPhysgunPickup to open admin menu on right-click
function ENT:OnPhysgunPickup(ply, phys)
    if not ReqSystem:IsAdmin(ply) then return true end -- Allow pickup for admins
    
    -- Check if player is holding right-click
    if ply:KeyDown(IN_ATTACK2) then
        local terminalId = self:GetNWInt("ReqSystem_TerminalID", 0)
        if terminalId > 0 then
            -- Send terminal admin menu
            net.Start("ReqSystem_OpenTerminalAdmin")
            net.WriteInt(terminalId, 32)
            net.Send(ply)
        end
        return false -- Prevent pickup
    end
    
    return true -- Allow normal pickup
end
