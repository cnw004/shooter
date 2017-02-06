function love.load()
	startGame = false

	player = { x = 400 - 55/2, y = love.graphics.getHeight() - 90, speed = 10, img = love.graphics.newImage("img/spaceship.png")}

	backgroundMusic = love.audio.newSource("sounds/galaga2.wav", "static")
	backgroundMusic:setLooping(true)

	--now some things for bullets
	shootSound = love.audio.newSource("sounds/shoot.wav", "static")
	canShoot = true
	bulletbulletTimerMax = 0.25
	bulletTimer = bulletbulletTimerMax

	bullet = love.graphics.newImage("img/bullet.png")
	bulletList = {}
	bulletVelocity = 10

	--enemy stuff
	enemyDeathSound = love.audio.newSource("sounds/invaderkilled.wav", "static")
	canSpawn = false
	enemyTimerMax = 0.6
	enemyTimer = enemyTimerMax

	enemy = love.graphics.newImage("img/enemy.png")
	enemyList = {}
	enemyVelocity = 4

	--keep track of score and lives
	heart = love.graphics.newImage("img/heart.png")
	playerDamaged = love.audio.newSource("sounds/explosion.wav", "static")
	playerDead = love.audio.newSource("sounds/explosion1.wav", "static")
	score = 0
	lives = 3
	isAlive = true
	endGame = false

	--level stuff
	level = 1

	--boss stuff
	bossImg = love.graphics.newImage("img/boss.png")
	boss = {x = 400 - bossImg:getWidth()/2, y = 25, img = bossImg}
	bossLife = 10
	bossAlive = false
	hasWon = false
	healthWidth = boss.img:getWidth()
	winSound = love.audio.newSource("sounds/extra_ship.wav")

end

function love.update(dt)
	if(isAlive and hasWon == false and startGame == true) then
		backgroundMusic:play()
	else
		backgroundMusic:stop()
	end
	
	if bossAlive == true then
		checkBossCollision()
		if bossLife <= 0 then
			winSound:play()
			bossAlive = false
			hasWon = true
		end
	end
	if isAlive and startGame == true and hasWon == false then 
		updateShoot()
		updateBullets()
		spawn()
		updateEnemies()
		fullCheckCollision()
		updateLevel()
		checkAlive() --changes isAlive if the player is out of lives
		if love.keyboard.isDown("left") and checkLeft(player.x, player.y) then
			player.x = player.x - player.speed
		end

		if love.keyboard.isDown("right") and checkRight(player.x, player.y) then
			player.x = player.x + player.speed
		end

		if love.keyboard.isDown("space") and canShoot then
			shoot()
		end
	elseif hasWon == true and isAlive == true then
		if love.keyboard.isDown("y") then
			startAgain()
		elseif love.keyboard.isDown("n") then
			love.event.quit()
		end
	elseif startGame == false then --first screen you see before starting the game
		if love.keyboard.isDown("s") then --start game
			startGame = true
		elseif love.keyboard.isDown("q") then --quit game
			love.event.quit()
		end
	elseif isAlive == false and endGame == false then
		playerDead:play()
		endGame = true
	elseif endGame == true then --endgame condition
		if love.keyboard.isDown("c") then
			resetGame()
		elseif love.keyboard.isDown("q") then
			love.event.quit()
		end
	end
end

function love.draw()
	if bossAlive == true and isAlive == true then
		drawBoss()
	end
	if hasWon == true and isAlive == true then
		drawWin()
	
	elseif isAlive and startGame == true then
		drawTop()
		love.graphics.draw(player.img, player.x, player.y) --update the player
		for i, bullet in ipairs(bulletList) do
			love.graphics.draw(bullet.img, bullet.x, bullet.y)
		end

		for i, enemy in ipairs(enemyList) do
			love.graphics.draw(enemy.img, enemy.x, enemy.y)
		end
	elseif startGame == false then
		drawStartGame()
	else
		drawTop()
		drawEndGame()
	end
end

function checkLeft(x, y) --make sure player not going off screen left
	if(player.x - player.img:getWidth()/2 + 20> 0) then --magic numbers needed to make it look perfect
		return true
	else
		return false
	end

end

function checkRight(x, y) --make sure player not going off screen right
	if (player.x + player.img:getWidth()+5 < love.graphics.getWidth()) then --magic number needed to make it look perfct
		return true
	else
		return false
	end
end

function updateShoot() --decides if i can shoot again yet or not
	bulletTimer = bulletTimer - (.01)
	if bulletTimer < 0 then
		canShoot = true
	end
end

function shoot() --call this when space is hit to shoot
	shootSound:play()
	newBullet = {x = player.x + player.img:getWidth()/2 -5, y = player.y, img = bullet}
	table.insert(bulletList, newBullet)
	canShoot = false
	bulletTimer = bulletbulletTimerMax


end

function updateBullets() --called in update to move the bullets up the screen
	for i, bullet in ipairs(bulletList) do
		bullet.y = bullet.y - bulletVelocity
		if bullet.y < 0 then
			table.remove(bulletList, i)
		end
	end

end

function spawn()
	enemyTimer = enemyTimer - .01
	if enemyTimer < 0 then
		enemyTimer = enemyTimerMax
		myRandom = math.random(enemy:getWidth(),  love.graphics.getWidth() - enemy:getWidth()) --love.graphics.getWidth() is the screen width
		newEnemy = {x = myRandom, y = -10, img = enemy}
		table.insert(enemyList, newEnemy)
	end

end

function updateEnemies()
	for i, enemy in ipairs(enemyList) do
		enemy.y = enemy.y + enemyVelocity
		if enemy.y > 850 then --if they go off screen
			playerDamaged:play()
			lives = lives - 1
			table.remove(enemyList, i)
		end
	end

end

function checkCollision(pX,pY, pW, pH, eX, eY, eW, eH) --true if the two boxes overlap false otherwise
	return (pX < eX+eW and eX < pX+pW and pY < eY+eH and eY < pY + pH)
end

function fullCheckCollision()
	for i, enemy in ipairs(enemyList) do
		for j, bullet in ipairs(bulletList) do
			if checkCollision(enemy.x,enemy.y, enemy.img:getWidth(), enemy.img:getHeight(), bullet.x, bullet.y, bullet.img:getWidth(), bullet.img:getHeight()) then
				enemyDeathSound:play()
				table.remove(bulletList, j)
				table.remove(enemyList, i)
				score = score + 1
			end
		end
		if checkCollision(enemy.x, enemy.y, enemy.img:getWidth(), enemy.img:getHeight(), player.x, player.y, player.img:getWidth(), player.img:getHeight()) and isAlive then
			playerDamaged:play()
			table.remove(enemyList,i)
			lives = lives - 1
		end
	end

end

function checkBossCollision()
	for i, bullet in ipairs(bulletList) do
		if checkCollision(boss.x, boss.y, boss.img:getWidth(), boss.img:getHeight(), bullet.x, bullet.y, bullet.img:getWidth(), bullet.img:getHeight()) and bossLife > 0 then
			bossLife = bossLife - 1
			healthWidth = healthWidth - boss.img:getWidth()/10
			enemyDeathSound:play()
			table.remove(bulletList, i)
		end
	end
end

function drawLives()
	love.graphics.print("Lives: ", love.graphics.getWidth()-heart:getWidth()*7-10, heart:getHeight(), 0, 2, 2)
	if lives == 3 then
		love.graphics.draw(heart, love.graphics.getWidth()-heart:getWidth()*6 + heart:getWidth()*2-10, heart:getHeight())
		love.graphics.draw(heart, love.graphics.getWidth()-heart:getWidth()*6 + heart:getWidth()*3, heart:getHeight())
		love.graphics.draw(heart, love.graphics.getWidth()-heart:getWidth()*6 + heart:getWidth()*4 + 10, heart:getHeight())
	elseif lives == 2 then
		love.graphics.draw(heart, love.graphics.getWidth()-heart:getWidth()*6 + heart:getWidth()*2-10, heart:getHeight())
		love.graphics.draw(heart, love.graphics.getWidth()-heart:getWidth()*6 + heart:getWidth()*3, heart:getHeight())
	elseif lives == 1 then
		love.graphics.draw(heart, love.graphics.getWidth()-heart:getWidth()*6 + heart:getWidth()*2-10, heart:getHeight())
	end

end

function drawScore()
	love.graphics.print("Score: " .. score, 10, heart:getHeight(), 0 , 2, 2)

end

function drawLevel()
	love.graphics.print("Level " .. level, 350, heart:getHeight(), 0, 2, 2)

end

function checkAlive()
	if lives <= 0 then
		isAlive = false
	end
end

function updateLevel()
	if score == 10 and level == 1 then
		level = level + 1
		enemy = love.graphics.newImage("img/enemy2.png")
		enemyVelocity = 4.2
	elseif score == 25 and level == 2 then
		level = level + 1
		enemy = love.graphics.newImage("img/enemy3.png")
		enemyVelocity = 4.4
	elseif score == 50 and level == 3 then
		level = level + 1
		enemy = love.graphics.newImage("img/enemy4.png")
		enemyVelocity = 4.6
	elseif score == 75 and level == 4 then
		level = level + 1
		enemy = love.graphics.newImage("img/enemy5.png")
		enemyVelocity = 4.8
	elseif score == 100 and level == 5 then
		level = level + 1
		bossAlive = true
		enemy = love.graphics.newImage("img/enemy6.png")
		enemyVelocity = 5
	end

end

function drawEndGame()
	love.graphics.print("Game Over", 300, 400, 0, 3, 3)
	love.graphics.print("Continue? (c)", 325, love.graphics.getHeight()/2, 0, 2, 2)
	love.graphics.print("Quit (q)", 350, 475, 0, 2, 2)

end

function resetGame()
	isAlive = true
	lives = 3
	score = 0
	endGame = false
	bulletList = {}
	enemyList = {}
	enemyTimer = enemyTimerMax
	level = 1
	bossLife = 10
	bossAlive = false
	hasWon = false
	healthWidth = boss.img:getWidth()
	enemy = love.graphics.newImage("img/enemy.png")

end

function drawStartGame()
	love.graphics.print("Space Attack!", 275, 400, 0, 3, 3)
	love.graphics.print("Start (s)", 350, love.graphics.getHeight()/2, 0, 2, 2)
	love.graphics.print("Quit (q)", 355, 475, 0, 2, 2)
	love.graphics.print("A Game by Cole Whitley", 275, 850, 0, 2, 2)
end

function drawTop()
	drawLives()
	drawScore()
	drawLevel()
end

function drawBoss()
	love.graphics.print("hp: ", boss.x-25, 2)
	love.graphics.rectangle("fill", boss.x, 2, healthWidth, 10)
	love.graphics.draw(boss.img, boss.x, boss.y) --perfect
end

function drawWin()
	love.graphics.print("You Win!", 275, 400, 0, 3, 3)
	love.graphics.print("Play again? (y/n)", 250, love.graphics.getHeight()/2, 0, 2, 2)
end

function startAgain()
	love.load()
end