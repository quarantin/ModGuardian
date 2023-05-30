require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISModalRichText"

ModGuardianPopup = ISPanelJoypad:derive("ModGuardianPopup")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_TITLE = getTextManager():getFontHeight(UIFont.Title)

function ModGuardianPopup:createChildren()
	local btnWid = 100
	local btnHgt = math.max(25, FONT_HGT_SMALL + 3 * 2)
	local padY = 10

	self.textureX = 10
	self.textureY = 10 + FONT_HGT_TITLE + 10
	self.textureW = self.texture:getWidth()
	self.textureH = self.texture:getHeight()

	local x = self.textureX + self.textureW
	local y = self.textureY
	self.richText = ISRichTextPanel:new(x, y, self.width - x, self.height - padY - btnHgt - padY - y)
	self.richText.background = false
	self.richText.autosetheight = false
	self.richText.clip = true
	self.richText.marginRight = self.richText.marginLeft
	self:addChild(self.richText)
	self.richText:addScrollBars()

	local message = getText(self.text, self.config.modID) .. "<BR><BR>" .. getText("UI_ModGuardian_Warning")
	self.richText:setText(message)
	self.richText:paginate()

	self.ok = ISButton:new((self:getWidth() / 2) - btnWid / 2, self:getHeight() - padY - btnHgt, btnWid, btnHgt, getText("UI_mainscreen_exit"), self, self.onOK)
	self.ok.anchorTop = false
	self.ok.anchorBottom = true
	self.ok:initialise()
	self.ok:instantiate()
	self:addChild(self.ok)
end

function ModGuardianPopup:render()
	ISPanelJoypad.render(self)
	self:drawTextCentre(getText("UI_ModGuardian_Title"), self.width / 2, 10, 1, 1, 1, 1, UIFont.Title);
	self:drawTextureScaledAspect(self.texture, self.textureX, self.textureY, self.textureW, self.textureH, 1, 1, 1, 1)
end

function ModGuardianPopup:onGainJoypadFocus(joypadData)
	ISPanelJoypad.onGainJoypadFocus(self, joypadData)
	self:setISButtonForA(self.ok)
end


function ModGuardianPopup:onOK(button, x, y)
	getCore():quitToDesktop()
end

function ModGuardianPopup:new(x, y, width, height, config, text)
	local o = ISPanelJoypad.new(self, x, y, width, height)
	o.backgroundColor.a = 0.9
	o.texture = getTexture("spiffoWarning.png")
	o.config = config
	o.text = text
	return o
end
