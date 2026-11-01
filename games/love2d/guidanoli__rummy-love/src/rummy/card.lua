local constants = require "rummy.constants"

local Card = {}
Card.__index = Card

function Card:__tostring()
    local rankName = constants.rankNames[self.rank]
    return ("%s of %s"):format(rankName, self.suit)
end

local validators = {
    rank = function (r)
        assert(constants.ranks[r] == true)
    end,
    suit = function (s)
        assert(constants.suits[s] == true)
    end,
    origin = function (o)
        assert(constants.origins[o] == true)
    end,
    pos = function (p)
        assert(type(p) == 'number')
        assert(p > 0)
    end,
    x = function (x)
        assert(type(x) == 'number')
        assert(x >= 0)
    end,
    y = function (y)
        assert(type(y) == 'number')
        assert(y >= 0)
    end,
    animation = function (a)
        if a ~= nil then
            assert(type(a) == 'table')
            assert(constants.animations[a.name] == true)
            assert(type(a.time) == 'number')
            assert(type(a.duration) == 'number')
        end
    end,
    selected = function (s)
        assert(type(s) == 'boolean')
    end,
    meldid = function (m)
        assert(type(m) == 'number')
    end
}

local function validate(key, value)
    local validator = validators[key]
    if validator == nil then
        error(("invalid key '%s'"):format(key))
    else
        validator(value)
    end
end

function Card:__newindex(key, value)
    validate(key, value)
    rawset(self, key, value)
end

function Card:new(t)
    for k, v in pairs(t) do
        validate(k, v)
    end
    setmetatable(t, self)
    return t
end

function Card:setOrigin(origin)
    validate('origin', origin)
    self.origin = origin
end

function Card:setPos(pos)
    validate('pos', pos)
    self.pos = pos
end

function Card:setX(x)
    validate('x', x)
    self.x = x
end

function Card:setY(y)
    validate('y', y)
    self.y = y
end

function Card:setAnimation(animation)
    validate('animation', animation)
    self.animation = animation
end

function Card:setSelected(selected)
    validate('selected', selected)
    self.selected = selected
end

function Card:setMeldId(meldid)
    validate('meldid', meldid)
    self.meldid = meldid
end

return Card
