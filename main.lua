require("Scripts/TSerial")
ai = require("Scripts/ai")
console = require("Scripts/console")
require("Scripts/imageManipulation")
require("Scripts/ui")
require("Scripts/misc")
require("Scripts/input")
quickHelp = require("Scripts/quickHelp")
button = require("Scripts/button")
menu = require("Scripts/menu")
msgBox = require("Scripts/msgBox")
tutorialBox = require("Scripts/tutorialBox")
codeBox = require("Scripts/codeBox")
map = require("Scripts/map")
train = require("Scripts/train")
functionQueue = require("Scripts/functionQueue")
passenger = require("Scripts/passenger")
stats = require("Scripts/statistics")
clouds = require("Scripts/clouds")
loadingScreen = require("Scripts/loadingScreen")
require("Scripts/globals")
numTrains = 0

FONT_BUTTON = love.graphics.newFont( "UbuntuFont/Ubuntu-B.ttf", 19 )
FONT_BUTTON_SMALL = love.graphics.newFont( "UbuntuFont/Ubuntu-B.ttf", 16 )
FONT_STANDARD = love.graphics.newFont("UbuntuFont/Ubuntu-B.ttf", 15 )
FONT_STAT_HEADING = love.graphics.newFont( "UbuntuFont/Ubuntu-B.ttf",18 )
FONT_STAT_MSGBOX = love.graphics.newFont( "UbuntuFont/Ubuntu-B.ttf",17 )
FONT_CONSOLE = love.graphics.newFont( "UbuntuFont/Ubuntu-R.ttf", 13)

PLAYERCOLOUR1 = {r=255,g=50,b=50}
PLAYERCOLOUR2 = {r=64,g=64,b=250}
PLAYERCOLOUR3 = {r=255,g=200,b=64}
PLAYERCOLOUR4 = {r=0,g=255,b=0}

PLAYERCOLOUR1_CONSOLE = {r=255,g=200,b=200}
PLAYERCOLOUR2_CONSOLE = {r=200,g=200,b=255}
PLAYERCOLOUR3_CONSOLE = {r=255,g=220,b=100}
PLAYERCOLOUR4_CONSOLE = {r=200,g=255,b=200}

time = 0
mouseLastX = 0
mouseLastY = 0
MAX_PAN = 500
camX, camY = 0,0
camZ = 0.7
mapMouseX, mapMouseY = 0,0

timeFactor = 1
curMap = false
showQuickHelp = false
showConsole = true
initialising = true

function love.load()

	initialising = true
	loadingScreen.reset()
	love.graphics.setBackgroundColor(BG_R, BG_G, BG_B, 255)

	button.init()
	msgBox.init()
	loadingScreen.init()
	quickHelp.init()
	stats.init()
end

function finishStartupProcess()
	console.init(love.graphics.getWidth(),love.graphics.getHeight()/2)


	map.init()

	console.add("Loaded...")

	menu.init()
end


local floatPanX, floatPanY = 0,0	-- keep "floating" into the same direction for a little while...

function love.update(dt)
	-- ai.run()
	-- time = time + dt
	
	--mapMouseX, mapMouseY = coordinatesToMap(love.mouse.getPosition())
			
			
	if initialising then
		button.init()
		msgBox.init()
		loadingScreen.init()
		quickHelp.init()
		stats.init()
		tutorialBox.init()
		codeBox.init()
		if button.initialised() and msgBox.initialised() and loadingScreen.initialised() and quickHelp.initialised() and stats.initialised() and tutorialBox.initialised() and codeBox.initialised() then
			initialising = false
			finishStartupProcess()
		end
	else
		functionQueue.run()
	
		button.calcMouseHover()
		if mapImage then
			
			if not roundEnded then
				map.handleEvents(dt)
			end
	
			prevX = camX
			prevY = camY
			if panningView then
				x, y = love.mouse.getPosition()
				camX = clamp(camX - (mouseLastX-x)*0.75/camZ, -MAX_PAN, MAX_PAN)
				camY = clamp(camY - (mouseLastY-y)*0.75/camZ, -MAX_PAN, MAX_PAN)
				mouseLastX = x
				mouseLastY = y
			
				floatPanX = (camX - prevX)*40
				floatPanY = (camY - prevY)*40
				
			else
				if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
					camX = clamp(camX + 300*dt/camZ, -MAX_PAN, MAX_PAN)
				end
				if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
					camX = clamp(camX - 300*dt/camZ, -MAX_PAN, MAX_PAN)
				end 
				if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
					camY = clamp(camY + 300*dt/camZ, -MAX_PAN, MAX_PAN)
				end
				if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
					camY = clamp(camY - 300*dt/camZ, -MAX_PAN, MAX_PAN)
				end
				if love.keyboard.isDown("q") then
					camZ = clamp(camZ + dt*0.25, 0.1, 1)
					camX = clamp(camX, -MAX_PAN, MAX_PAN)
					camY = clamp(camY, -MAX_PAN, MAX_PAN)
				end
				if love.keyboard.isDown("e") then
					camZ = clamp(camZ - dt*0.25, 0.1, 1)
					camX = clamp(camX, -MAX_PAN, MAX_PAN)
					camY = clamp(camY, -MAX_PAN, MAX_PAN)
				end
			
				if camX ~= prevX or camY ~= prevY then
					floatPanX = (camX - prevX)*20
					floatPanY = (camY - prevY)*20
				end
			end
			if camX == prevX and camY == prevY then
				floatPanX = floatPanX*math.max(1 - dt*3, 0)
				floatPanY = floatPanY*math.max(1 - dt*3, 0)
				camX = clamp(camX + floatPanX*dt, -MAX_PAN, MAX_PAN)
				camY = clamp(camY + floatPanY*dt, -MAX_PAN, MAX_PAN)
			end
		elseif map.startupProcess() then
			if mapGenerateThread then
				err = mapGenerateThread:get("error")
				if err then
					print("Error in thread", err)
				end
				curMap = map.generate()
			elseif mapRenderThread then
				err = mapRenderThread:get("error")
				if err then
					print("Error in thread", err)
				end
				mapImage,mapShadowImage,mapObjectImage = map.render()
			end
			if train.isRenderingImages() then
				train.renderTrainImage()
			end
			
			if not train.isRenderingImages() and not mapGenerateThread and not mapRenderThread then	-- done rendering everything!
				runMap()	-- start the map!
			end
		else
			if menu.isRenderingImages() then
				menu.renderTrainImages()
			end
		end
		
		
	
		if not roundEnded then
			train.moveAll()
			if curMap then
				curMap.time = curMap.time + dt*timeFactor
			end
		end
	end
end


function love.draw()

	if initialising then		--only runs once at startup, until all images are rendered.
		loadingScreen.render()
		return
	end

	-- love.graphics.rectangle("fill",50,50,300,300)
	dt = love.timer.getDelta()
	passedTime = dt*timeFactor
	if mapImage then
		love.graphics.push()
		love.graphics.scale(camZ)
		
		love.graphics.translate(camX + love.graphics.getWidth()/(2*camZ), camY + love.graphics.getHeight()/(2*camZ))
		love.graphics.rotate(CAM_ANGLE)
		love.graphics.setColor(30,10,5, 150)
		love.graphics.rectangle("fill", -TILE_SIZE*(curMap.width+2)/2-120,-TILE_SIZE*(curMap.height+2)/2-80, TILE_SIZE*(curMap.width+2)+200, TILE_SIZE*(curMap.height+2)+200)
		love.graphics.setColor(0,0,0, 100)
		love.graphics.rectangle("fill", -TILE_SIZE*(curMap.width+2)/2-20, -TILE_SIZE*(curMap.height+2)/2+20, TILE_SIZE*(curMap.width+2), TILE_SIZE*(curMap.height+2))
		love.graphics.setColor(255,255,255, 255)
		love.graphics.draw(mapImage, -TILE_SIZE*(curMap.width+2)/2, -TILE_SIZE*(curMap.height+2)/2)
		
		
		love.graphics.translate(-TILE_SIZE*(curMap.width+2)/2, -TILE_SIZE*(curMap.height+2)/2)
		
		
		--love.graphics.setColor(255,255,255,255)
		--love.graphics.circle("fill", mapMouseX, mapMouseY, 20)
		
		passenger.showAll(passedTime)
		train.showAll()
		passenger.showVIPs(passedTime)
		
		love.graphics.setColor(255,255,255,255)
		love.graphics.draw(mapShadowImage, 0,0)	
		love.graphics.draw(mapObjectImage, 0,0)	
		
		map.renderHighlights(passedTime)
		
		if not love.keyboard.isDown("i") then clouds.renderShadows(passedTime) end
	
		map.drawOccupation()
			
		--love.graphics.setColor(255,255,255, 50)
		--love.graphics.draw(cl, -TILE_SIZE*(curMap.width+2)/2, -TILE_SIZE*(curMap.width+2)/2)
		
		--if love.mouse.isDown("l") then
		--end
		
		love.graphics.pop()
		love.graphics.push()
		love.graphics.scale(camZ*1.5)
		
		love.graphics.translate(camX + love.graphics.getWidth()/(camZ*3), camY + love.graphics.getHeight()/(camZ*3))
		love.graphics.rotate(CAM_ANGLE)
		love.graphics.translate(-TILE_SIZE*(curMap.width+2)/2, -TILE_SIZE*(curMap.height+2)/2)
		--love.graphics.translate(-TILE_SIZE*(curMap.width+2)/2, -TILE_SIZE*(curMap.height+2)/2)
		--love.graphics.translate(-TILE_SIZE*(curMap.width+2)/2, -TILE_SIZE*(curMap.height+2)/2)
		
		clouds.render()
		--love.graphics.translate(camX + love.graphics.getWidth()/2/camZ, camY + love.graphics.getHeight()/2/camZ)
		
		love.graphics.pop()
		
		if showQuickHelp then quickHelp.show() end
		if showConsole then console.show() end
		
	elseif mapGenerateThread or mapRenderThread then -- or trainGenerateThreads > 0 then
		loadingScreen.render()
	end

	
	--love.graphics.setColor(255,255,255,50)
	--love.graphics.circle("fill", mapMouseX, mapMouseY, 20)
	--[[
	love.graphics.print("mouse x " .. mapMouseX, 10, 200)
	love.graphics.print("mouse y " .. mapMouseY, 10, 220)
	love.graphics.print("normal mouse x " .. love.mouse.getX(), 10, 240)
	love.graphics.print("normal mouse y " .. love.mouse.getY(), 10, 260)
	]]--
	
	if roundEnded and curMap and mapImage then stats.display(love.graphics.getWidth()/2-175, 40, dt) end
	if msgBox.isVisible() then
		msgBox.show()
	else
		tutorialBox.show()
		codeBox.show()
	end
	button.show()
	menu.render()
	
	if love.keyboard.isDown(" ") then
		love.graphics.setFont(FONT_CONSOLE)
		love.graphics.setColor(255,255,255,255)
		love.graphics.print("FPS: " .. tostring(love.timer.getFPS( )), love.graphics.getWidth()-150, 5)
		love.graphics.print('RAM: ' .. collectgarbage('count'), love.graphics.getWidth()-150,20)
		love.graphics.print('X: ' .. camX, love.graphics.getWidth()-150,35)
		love.graphics.print('Y: ' .. camY, love.graphics.getWidth()-150,50)
		love.graphics.print('Z ' .. camZ, love.graphics.getWidth()-150,65)
		love.graphics.print('Passengers: ' .. MAX_NUM_PASSENGERS, love.graphics.getWidth()-150,80)
		love.graphics.print('Trains: ' .. numTrains, love.graphics.getWidth()-150,95)
		love.graphics.print('x ' .. timeFactor, love.graphics.getWidth()-150,110)
		if curMap then love.graphics.print('time ' .. curMap.time, love.graphics.getWidth()-150,125) end
	end
	
end

function love.quit()
	print("Closing.")
end
