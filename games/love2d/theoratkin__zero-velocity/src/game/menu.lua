---
-- Menu is responsible for drawing text entries that it holds,
-- and handling input for interaction with them.
--
-- classmod: Menu

Object = require "classic"
Vector = require "vector"

local Menu = Object:extend()

--[[--
  An entry is simply text that can be optionally selected.
  table: Entry
  
  ?string: text           Content of the entry.

  ?function: textFunc     Function that sets text.
  
  ?bool: select           Whether the entry is selectable.
  
  ?table: color           Entry color in the form of {r, g, b, a}.

  ?number: scale          Font scale.

  ?number: lineHeight     Line height.
  
  ?function: onselection  Function that is called with a boolean value
                          when the entry is selected or deselected.
  
  ?function: onenter      Function that is called when the selection is entered.
]]

function Menu:new(input, font)
	--- Table that holds all entries.
	-- Read-only; use Menu:add() to add new entries.
	-- see: Menu:add
	self.entries = {}

	--- Inactive menu is not drawn and ignores all input.
	self.active = false
	--- Invisible menu is not drawn.
	self.visible = true
	--- Unfocused menu ignores all input.
	self.focused = false

	--- Alignment of all entries relative to the center of the screen.
	-- Can be either left, right or center.
	self.alignment = "left"
	--- Offset relative to the center of the screen.
	self.offset = 50

	--- Whether selected entry is outlined even when the menu is not focused.
	self.outlineSelection = false
	--- Use alpha component instead of simply multiplying RBG values by alpha.
	self.trueTransparency = false

	--- Callback for when the back button gets pressed while focused.
	self.onback = nil
	--- Callback for when the left button gets pressed while focused.
	self.onleft = nil
	--- Callback for when the right button gets pressed while focused.
	self.onright = nil

	--- Function that gets called before each draw call.
	self.beforedraw = nil

	--- Entries font.
	self.font = font
	--- Default line height multiplier.
	self.lineHeight = 2.5

	self._input = input
	--self._center = Vector(love.graphics.getDimensions())
	self._center = Vector(960, 540)
	self._selection = 0
	self._selectionOffset = 10
	-- Prevents immediate onenter() call when coming from another menu and
	-- input:down("fire") is still true.
	self._repeatedPressSafeguard = false
end


--- Add an entry to the menu.
-- tparam: Entry entry  Entry to add.
function Menu:add(entry)
	-- Setting default values.
	entry = entry or {}
	entry.text = entry.text or ""
	if entry.textFunc then
		entry.text = entry.textFunc()
	end
	entry.color = entry.color or {1, 1, 1, 0.2}
	entry.scale = entry.scale or 1.0
	entry.lineHeight = entry.lineHeight or self.font:getHeight() * self.lineHeight

	table.insert(self.entries, entry)

	-- Selecting first button.
	if entry.select and self._selection == 0 then
		self._selection = #self.entries
	end
end


function Menu:updateText()
	for _, entry in pairs(self.entries) do
		if entry.textFunc then
			entry.text = entry.textFunc()
		end
	end
end


--- Update the menu.
-- Won't do anything if self.focused or self.active are set to false.
-- number: dt  Delta time.
-- see: self.focused
-- see: self.active
function Menu:update(dt)
	if not self.focused or not self.active then
		self._repeatedPressSafeguard = true
		return
	end

	if self._repeatedPressSafeguard then
		self._repeatedPressSafeguard = false
		return
	end

	if (self._input:down("up") or self._input:down("down")) and
		self._selection ~= 0
	then
		local max = 1
		local step = -1
		if self._input:down("down") then
			max = #self.entries
			step = 1
		end
		local origSel = self._selection
		if self._selection ~= max then
			self:_callOnSelection(false)
			-- Skip through entries that aren't buttons.
			repeat
				self._selection = self._selection + step
			until (self._selection == max or
			       self:selectedEntry().select)
			if self:selectedEntry().select then
				self:_callOnSelection(true)
			else
				self._selection = origSel
			end
		end
	end

	if self._input:down("fire") or self._input:down("right") then
		local entry = self:selectedEntry()
		if entry then
			if entry.onenter then
				entry.onenter()
			end
			if entry.textFunc then
				entry.text = entry.textFunc()
			end
		end
	end

	for i, mapping in pairs({ "back", "right", "left" }) do
		if self._input:down(mapping) and self["on"..mapping] then
			self["on"..mapping]()
		end
	end
end


--- Draw all entries.
--
-- Won't do anything if self.active is set to false.
--
-- Won't draw anything if self.visible is set to false,
-- but self.beforedraw() will still get called.
-- see: self.active
-- see: self.visible
-- see: self.beforedraw
function Menu:draw()
	if not self.active then
		return
	end

	if self.beforedraw then
		self.beforedraw()
	end

	if not self.visible then
		return
	end

	for i, entry in pairs(self.entries) do
		self:_drawEntry(i, entry)
	end
end


--- Set screen size.
-- int: w  Width.
-- int: h  Height.
function Menu:resize(w, h)
	self._center.x = w / 2
	self._center.y = h / 2
end


--- Select first selectable entry, if there is any.
function Menu:selectFirst()
	for i, entry in pairs(self.entries) do
		if entry.select then
			self._selection = i
			return
		end
	end
end


--- Get currently selected entry or nil if there are no selectable entries.
-- treturn: Entry
function Menu:selectedEntry()
	return self.entries[self._selection]
end


--[[ Private methods -----------------------------------]]--


function Menu:_callOnSelection(value)
	local entry = self:selectedEntry()
	if entry and entry.onselection then
		entry.onselection(value)
	end
end


function Menu:_alignCenter(text, scale)
	return self._center.x - self.font:getWidth(text) / 2 * scale
end


function Menu:_alignLeft(text, scale, offset)
	return self._center.x - self.font:getWidth(text) * scale - offset
end


function Menu:_alignRight(text, scale, offset)
	return self._center.x + offset
end


function Menu:_print(text, x, y, scale)
	love.graphics.print(text, x, y, 0, scale, scale)
end


function Menu:_getEntryHeight(i, lineHeight)
	return self._center.y + lineHeight * (i - #self.entries / 2 - 0.66)
end


function Menu:_drawEntry(i, entry)
	local height = self:_getEntryHeight(i, entry.lineHeight)

	-- Drawing selection line.
	if i == self._selection then
		self:_drawSelectionLine(height, entry.lineHeight)
	end

	-- Set transparency.
	if self.trueTransparency then
		love.graphics.setColor(entry.color)
	else
		local a = entry.color[4]
		love.graphics.setColor(
			entry.color[1] * a,
			entry.color[2] * a,
			entry.color[3] * a
		)
	end
	-- Get alignment function name by capitalizing first letter.
	local alignFunc = "_align" .. self.alignment:gsub("^%l", string.upper)
	self:_print(
		entry.text,
		self[alignFunc](self, entry.text, entry.scale, self.offset),
		height,
		entry.scale
	)
end


function Menu:_drawSelectionLine(height, lineHeight)
	if not (self.focused or self.outlineSelection) then
		return
	end

	local ax = self._center.x - self.offset + self._selectionOffset
	local bx = 0
	if self.alignment == "right" then
		ax = self._center.x + self.offset - self._selectionOffset
		bx = 1920
	elseif self.alignment == "center" then
		ax = 1920
	end

	local halfHeight = lineHeight / 2
	local vOffset = self.font:getHeight() / 2
	local ay = height + halfHeight + vOffset
	local by = height - halfHeight + vOffset

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setLineWidth(3)
	love.graphics.polygon(
		self.focused and "fill" or "line", 
		ax, ay, ax, by, bx, by, bx, ay
	)
end


return Menu
