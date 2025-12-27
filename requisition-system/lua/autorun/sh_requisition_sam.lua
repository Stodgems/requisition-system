-- SAM Integration for Requisition System

-- Wait for SAM to load
hook.Add("Initialize", "ReqSystem_SAM_Integration", function()
    -- Check if SAM is installed
    if not sam then return end
    
    -- Register permissions with SAM
    sam.permissions.add("requisition_admin", "Requisition System", "superadmin")
    
    -- SAM permissions registered
    
    -- Override the IsAdmin function to use SAM permissions
    function ReqSystem:IsAdmin(ply)
        if not IsValid(ply) then return false end
        
        -- Check SAM permission for full admin access
        if ply:HasPermission("requisition_admin") then
            return true
        end
        
        -- Fallback to original usergroup check
        local usergroup = ply:GetUserGroup()
        return self.Config.AdminRanks[usergroup] == true
    end
end)

-- SAM integration loaded
