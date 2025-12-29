-- Client-side colored chat message receiver

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

print("[Requisition System] Client-side colored chat loaded!")
