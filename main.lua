application:configureFrustum(30)
application:setBackgroundColor(0x00DDFF)
stage:addEventListener(Event.KEY_UP, function(event)
   if event.keyCode == KeyCode.BACK then application:exit() end
end)

setGameState(gameStates.world)
