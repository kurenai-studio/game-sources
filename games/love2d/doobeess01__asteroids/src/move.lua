directions = {
    right={1,0},
    left={-1,0},
    up={0,-1},
    down={0,1}
}
function move_direction(entity, direction, dt)
    move(entity, directions[direction][1]*entity.speed, directions[direction][2]*entity.speed, dt)
end

function move(entity, dx, dy, dt)
    entity.x = entity.x + dx*dt
    entity.y = entity.y + dy*dt
end


function move_projectiles(projectiles, dt)
    window_width,window_height,flags = love.window.getMode()

    local new_projectiles = {}
    for i,projectile in pairs(projectiles) do
        move(projectile, projectile.dx, projectile.dy, dt)
        if (-projectile.width < projectile.x) and (projectile.x <= window_width) and (projectile.y <= window_height) then
            new_projectiles[#new_projectiles+1] = projectile
        end
    end

    projectiles = new_projectiles
end