local collision = {}

function collision.aabb(a, b)
return a.x < b.x + b.w and
b.x < a.x + a.w and
a.y < b.y + b.h and
b.y < a.y + a.h
end

return collision
