if SKConfig.DisablePauseMenu then return end

RegisterNetEvent('streetkings:pausemenu:exitGame', function()
    local src = source
    DropPlayer(src, 'Thank you for playing NZ Cars and Coffee!')
end)