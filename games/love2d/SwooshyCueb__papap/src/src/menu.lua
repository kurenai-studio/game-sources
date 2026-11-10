require('extern/class')
require('colors')
require('common')

menu = class()

function menu:init(name, tp)
    tp = tp or false
    mw, mh, _ = love.window.getMode()
    self.basecanvas = love.graphics.newCanvas(mw, mh)
    self.btncanvas = love.graphics.newCanvas(mw, mh)
    self.canvas = love.graphics.newCanvas(mw, mh)
    tempcanvas = love.graphics.newCanvas(mw, mh)
    t1 = love.graphics.newText(lgfont_std, nil)
    t2 = love.graphics.newText(lgfont_std, nil)
    local tn = love.graphics.newText(smfont_std, nil)
    tc = love.graphics.newText(smfont_fxw, nil)

    self.btns = {}
    self.sel = 1

    t1:set({colors.title_text, 'pipes'})
    t2:set({colors.title_text, 'and'})

    tn:set({colors.menu_name, name})

    tc:set({colors.title_text, 'controls (keyboard):\n', colors.menu_text,
        '  change selection:     arrow keys or wasd\n' ..
        '  play piece/activate:  space, enter or E\n' ..
        '  speed up:             shift\n' ..
        '  pause game:           escape\n\n',
        colors.title_text, 'controls (controller):\n', colors.menu_text,
        '  change selection:     d-pad\n' ..
        '  play piece/activate:  A\n' ..
        '  speed up:             X\n' ..
        '  pause game:           start'
    })

    love.graphics.setLineWidth(1)
    love.graphics.setCanvas(tempcanvas)
        love.graphics.setBackgroundColor(colors.invis)
        love.graphics.clear()
        love.graphics.setColor(colors.menu_shadow)
            love.graphics.rectangle('line', ((mw-320)/2)+8, ((mh-480)*1/24)+8, 312, 128, 6, 6)
            love.graphics.rectangle('line', ((mw-320)/2)+7, ((mh-480)*1/24)+7, 312, 128, 6, 6)
            love.graphics.rectangle('line', ((mw-320)/2)+6, ((mh-480)*1/24)+6, 312, 128, 6, 6)
            love.graphics.rectangle('line', ((mw-320)/2)+5, ((mh-480)*1/24)+5, 312, 128, 6, 6)
            love.graphics.rectangle('line', ((mw-320)/2)+4, ((mh-480)*1/24)+4, 312, 128, 6, 6)
            love.graphics.rectangle('line', ((mw-320)/2)+3, ((mh-480)*1/24)+3, 312, 128, 6, 6)
            love.graphics.rectangle('line', ((mw-320)/2)+2, ((mh-480)*1/24)+2, 312, 128, 6, 6)
            love.graphics.rectangle('line', ((mw-320)/2)+1, ((mh-480)*1/24)+1, 312, 128, 6, 6)
        love.graphics.setColor(colors.menu_bg)
            love.graphics.rectangle('fill', (mw-320)/2, (mh-480)*1/24, 312, 128, 6, 6)
        love.graphics.setColor(colors.menu_border)
            love.graphics.rectangle('line', (mw-320)/2, (mh-480)*1/24, 312, 128, 6, 6)
        love.graphics.setColor(colors.default)
        love.graphics.draw(t1, ((mw-320)/2)+(312/2)-(t1:getWidth()/2), 6)
        love.graphics.draw(t2, ((mw-320)/2)+(312/2)-(t2:getWidth()/2), 30)
        love.graphics.draw(t1, ((mw-320)/2)+(312/2)-(t1:getWidth()/2), 54)
        love.graphics.draw(t2, ((mw-320)/2)+(312/2)-(t2:getWidth()/2), 78)
        love.graphics.draw(t1, ((mw-320)/2)+(312/2)-(t1:getWidth()/2), 102)
        love.graphics.setColor(colors.menu_shadow)
            love.graphics.rectangle('line', ((mw-320)/2)+8, ((mh-480)*7/8)+472-(tc:getHeight()+16)+8, 312, (tc:getHeight()+16), 6, 6)
            love.graphics.rectangle('line', ((mw-320)/2)+7, ((mh-480)*7/8)+472-(tc:getHeight()+16)+7, 312, (tc:getHeight()+16), 6, 6)
            love.graphics.rectangle('line', ((mw-320)/2)+6, ((mh-480)*7/8)+472-(tc:getHeight()+16)+6, 312, (tc:getHeight()+16), 6, 6)
            love.graphics.rectangle('line', ((mw-320)/2)+5, ((mh-480)*7/8)+472-(tc:getHeight()+16)+5, 312, (tc:getHeight()+16), 6, 6)
            love.graphics.rectangle('line', ((mw-320)/2)+4, ((mh-480)*7/8)+472-(tc:getHeight()+16)+4, 312, (tc:getHeight()+16), 6, 6)
            love.graphics.rectangle('line', ((mw-320)/2)+3, ((mh-480)*7/8)+472-(tc:getHeight()+16)+3, 312, (tc:getHeight()+16), 6, 6)
            love.graphics.rectangle('line', ((mw-320)/2)+2, ((mh-480)*7/8)+472-(tc:getHeight()+16)+2, 312, (tc:getHeight()+16), 6, 6)
            love.graphics.rectangle('line', ((mw-320)/2)+1, ((mh-480)*7/8)+472-(tc:getHeight()+16)+1, 312, (tc:getHeight()+16), 6, 6)
        love.graphics.setColor(colors.menu_bg)
            love.graphics.rectangle('fill', (mw-320)/2, ((mh-480)*7/8)+472-(tc:getHeight()+16), 312, (tc:getHeight()+16), 6, 6)
        love.graphics.setColor(colors.menu_border)
            love.graphics.rectangle('line', (mw-320)/2, ((mh-480)*7/8)+472-(tc:getHeight()+16), 312, (tc:getHeight()+16), 6, 6)
        love.graphics.setColor(colors.default)
        love.graphics.draw(tc, ((mw-320)/2)+(312/2)-(tc:getWidth()/2), ((mh-480)*7/8)+472-(tc:getHeight()+8))
        love.graphics.setColor(colors.menu_shadow)
            love.graphics.rectangle('line', ((mw-320)/2)+8, ((mh-480)*7/8)+8, 312, 472-(tc:getHeight()+28), 6, 6)
            love.graphics.rectangle('line', ((mw-320)/2)+7, ((mh-480)*7/8)+7, 312, 472-(tc:getHeight()+28), 6, 6)
            love.graphics.rectangle('line', ((mw-320)/2)+6, ((mh-480)*7/8)+6, 312, 472-(tc:getHeight()+28), 6, 6)
            love.graphics.rectangle('line', ((mw-320)/2)+5, ((mh-480)*7/8)+5, 312, 472-(tc:getHeight()+28), 6, 6)
            love.graphics.rectangle('line', ((mw-320)/2)+4, ((mh-480)*7/8)+4, 312, 472-(tc:getHeight()+28), 6, 6)
            love.graphics.rectangle('line', ((mw-320)/2)+3, ((mh-480)*7/8)+3, 312, 472-(tc:getHeight()+28), 6, 6)
            love.graphics.rectangle('line', ((mw-320)/2)+2, ((mh-480)*7/8)+2, 312, 472-(tc:getHeight()+28), 6, 6)
            love.graphics.rectangle('line', ((mw-320)/2)+1, ((mh-480)*7/8)+1, 312, 472-(tc:getHeight()+28), 6, 6)
        love.graphics.setColor(colors.menu_bg)
            love.graphics.rectangle('fill', (mw-320)/2, (mh-480)*7/8, 312, 472-(tc:getHeight()+28), 6, 6)
        love.graphics.setColor(colors.menu_border)
            love.graphics.rectangle('line', (mw-320)/2, (mh-480)*7/8, 312, 472-(tc:getHeight()+28), 6, 6)
        love.graphics.setColor(colors.default)
        love.graphics.draw(tn, ((mw-320)/2)+(312/2)-(tn:getWidth()/2), ((mh-480)*7/8)+8)
    love.graphics.setCanvas(self.basecanvas)
        love.graphics.setBackgroundColor(colors.menu_backdrop)
        love.graphics.setBackgroundColor(colors.invis)
        love.graphics.clear()
        love.graphics.setColor(colors.menu_backdrop)
            love.graphics.rectangle('fill', 0, 0, mw, mh)
        love.graphics.setColor(colors.default)
        love.graphics.draw(tempcanvas)
    love.graphics.setCanvas()
end

function menu:add_button(text, retval)
    --printf('%s: 0x%08x\n', text, retval)
    local tb = love.graphics.newText(igfont_std, nil)
    tb:set({colors.btn_text, text})
    table.insert(self.btns, {text = tb, val = retval})
end

function menu:finalize()
    love.graphics.setCanvas(self.btncanvas)
        love.graphics.setBackgroundColor(colors.invis)
        love.graphics.clear()
        love.graphics.draw(self.basecanvas)
        love.graphics.setLineWidth(2)
        for bi = 1, table.getn(self.btns) do
            love.graphics.setColor(colors.btn_bg)
                love.graphics.rectangle('fill', ((mw-320)/2)+(312/2)-(128/2), ((mh-480)*7/8)+382-(tc:getHeight()+((table.getn(self.btns)-bi)*48)), 128, 32)
            love.graphics.setColor(colors.btn_border)
                love.graphics.rectangle('line', ((mw-320)/2)+(312/2)-(128/2), ((mh-480)*7/8)+382-(tc:getHeight()+((table.getn(self.btns)-bi)*48)), 128, 32)
            love.graphics.setColor(colors.default)
            love.graphics.draw(self.btns[bi].text, ((mw-320)/2)+(312/2)-(self.btns[bi].text:getWidth()/2), ((mh-480)*7/8)+389-(tc:getHeight()+((table.getn(self.btns)-bi)*48)))
        end
    love.graphics.setCanvas()
    self:render()
end

function menu:render()
    love.graphics.setCanvas(self.canvas)
        love.graphics.setBackgroundColor(colors.invis)
        love.graphics.clear()
        love.graphics.draw(self.btncanvas)
        love.graphics.setLineWidth(2)
        love.graphics.setColor(colors.btn_sel)
            love.graphics.rectangle('line', ((mw-320)/2)+(312/2)-(128/2), ((mh-480)*7/8)+382-(tc:getHeight()+((table.getn(self.btns)-self.sel)*48)), 128, 32)
        love.graphics.setColor(colors.default)
    love.graphics.setCanvas()
end

function menu:movsel(dir)
    if dir == DIR_UP then
        self.sel = clamp(1, table.getn(self.btns), self.sel-1)
    elseif dir == DIR_DOWN then
        self.sel = clamp(1, table.getn(self.btns), self.sel+1)
    end
    self:render()
end

function menu:press()
    return self.btns[self.sel].val
end
