
local pet = {
    hunger = 50,    
    happiness = 50, 
    health = 100,   
    age = 0         
}

local updateTimer = 0
local updateInterval = 1 

function love.load()
    love.window.setTitle("Tamagotchi en Love2D")
    love.graphics.setFont(love.graphics.newFont(16))
end

function love.update(dt)
    updateTimer = updateTimer + dt
    if updateTimer >= updateInterval then
        updatePet()
        updateTimer = 0 
    end
end

function love.draw()
    love.graphics.setBackgroundColor(0.9, 0.9, 0.9) 

    love.graphics.setColor(0, 0, 0) 
    love.graphics.print("Faim: " .. math.floor(pet.hunger), 20, 20)
    love.graphics.print("Bonheur: " .. math.floor(pet.happiness), 20, 50)
    love.graphics.print("Santé: " .. math.floor(pet.health), 20, 80)
    love.graphics.print("Âge: " .. math.floor(pet.age), 20, 110)

    love.graphics.print("Appuie sur 'F' pour nourrir", 20, 160)
    love.graphics.print("Appuie sur 'P' pour jouer", 20, 190)

    love.graphics.setColor(0.2, 0.8, 0.2) 
    love.graphics.circle("fill", 400, 300, 50) 
    love.graphics.setColor(0, 0, 0) 
    love.graphics.circle("fill", 380, 280, 5) 
    love.graphics.circle("fill", 420, 280, 5) 

    if pet.happiness > 50 then
        love.graphics.arc("fill", 400, 320, 20, math.pi, 2 * math.pi) 
    else
        love.graphics.arc("fill", 400, 320, 20, 0, math.pi)
    end
    
    if pet.health <= 0 then
        love.graphics.setColor(1, 0, 0) 
        love.graphics.print("Votre Tamagotchi est mort !", 300, 500)
    end
end

function love.keypressed(key)
    if pet.health > 0 then
        if key == "f" then
            feedPet()
        elseif key == "p" then
            playWithPet()
        end
    end
end

function updatePet()
    pet.hunger = pet.hunger + 2
    pet.happiness = pet.happiness - 1
    pet.age = pet.age + 1

    if pet.hunger > 100 then
        pet.health = pet.health - 5
        pet.hunger = 100 
    end

    if pet.happiness < 0 then pet.happiness = 0 end
    if pet.health < 0 then pet.health = 0 end
end

function feedPet()
    pet.hunger = pet.hunger - 20
    pet.happiness = pet.happiness + 5
    if pet.hunger < 0 then pet.hunger = 0 end
    if pet.happiness > 100 then pet.happiness = 100 end
end

function playWithPet()
    pet.happiness = pet.happiness + 15
    pet.hunger = pet.hunger + 5
    if pet.happiness > 100 then pet.happiness = 100 end
    if pet.hunger > 100 then pet.hunger = 100 end
end
