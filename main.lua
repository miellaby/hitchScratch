application:configureFrustum(30)
application:setBackgroundColor(0x00DDFF)
stage:addEventListener(Event.KEY_UP, function(event)
   if event.keyCode == KeyCode.BACK then application:exit() end
end)

application:setScaleMode("pixelPerfect")
-- local dw=application:getDeviceWidth()
-- local dh=application:getDeviceHeight()
-- application:setLogicalDimensions(dw,dh)
-- local scrw=application:getContentWidth()
-- local scrh=application:getContentHeight()

game:setState(game.State.WORLD)
-- game:setState(game.State.OVERFLY)
