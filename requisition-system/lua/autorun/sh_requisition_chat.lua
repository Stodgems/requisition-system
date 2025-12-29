-- Shared colored chat message system

if SERVER then
    util.AddNetworkString("ReqSystem_ColoredChat")
    
    -- Helper function for colored chat messages
    function ReqChatPrint(ply, message, isError)
        if not IsValid(ply) then return end
        
        net.Start("ReqSystem_ColoredChat")
        net.WriteString(message)
        net.WriteBool(isError or false)
        net.Send(ply)
    end
else
    -- Client receives and displays colored message
    net.Receive("ReqSystem_ColoredChat", function()
        local message = net.ReadString()
        local isError = net.ReadBool()
        
        if isError then
            chat.AddText(
                Color(255, 100, 100), "[Requisition] ERROR: ",
                Color(255, 255, 255), message
            )
        else
            chat.AddText(
                Color(100, 255, 150), "[Requisition] ",
                Color(255, 255, 255), message
            )
        end
    end)
end

print("[Requisition System] Colored chat system loaded!")
