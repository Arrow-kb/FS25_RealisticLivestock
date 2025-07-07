RL_BroadcastSettingsEvent = {}

local RL_BroadcastSettingsEvent_mt = Class(RL_BroadcastSettingsEvent, Event)
InitEventClass(RL_BroadcastSettingsEvent, "RL_BroadcastSettingsEvent")


function RL_BroadcastSettingsEvent.emptyNew()
    local self = Event.new(RL_BroadcastSettingsEvent_mt)
    return self
end


function RL_BroadcastSettingsEvent.new(setting)

    local self = RL_BroadcastSettingsEvent.emptyNew()

    self.setting = setting

    return self

end


function RL_BroadcastSettingsEvent:readStream(streamId, connection)
    
    local readAll = streamReadBool(streamId)

    if readAll then

        for _, setting in pairs(RLSettings.SETTINGS) do

            if setting.ignore then continue end
            
            local name = streamReadString(streamId)
            local state = streamReadUInt8(streamId)

            RLSettings.SETTINGS[name].state = state

        end

    else
            
        local name = streamReadString(streamId)
        local state = streamReadUInt8(streamId)

        RLSettings.SETTINGS[name].state = state
        self.setting = name

    end

    self:run(connection)

end


function RL_BroadcastSettingsEvent:writeStream(streamId, connection)
        
    streamWriteBool(streamId, self.setting == nil)

    if self.setting == nil then

        for name, setting in pairs(RLSettings.SETTINGS) do
            if setting.ignore then continue end
            streamWriteString(streamId, name)
            streamWriteUInt8(streamId, setting.state)
        end

    else

        local setting = RLSettings.SETTINGS[self.setting]
        streamWriteString(streamId, self.setting)
        streamWriteUInt8(streamId, setting.state)

    end

end


function RL_BroadcastSettingsEvent:run(connection)

    if self.setting == nil then

        for name, setting in pairs(RLSettings.SETTINGS) do
            if setting.ignore then continue end
            setting.element:setState(setting.state)
            if setting.callback ~= nil then setting.callback(name, setting.values[setting.state]) end 
        end

    else
            
        local setting = RLSettings.SETTINGS[self.setting]
        if setting.element ~= nil then setting.element:setState(setting.state) end
        if setting.callback ~= nil then setting.callback(self.setting, setting.values[setting.state]) end

        if setting.dynamicTooltip and setting.element ~= nil then setting.element.elements[1]:setText(g_i18n:getText("rl_settings_" .. self.setting .. "_tooltip_" .. setting.state)) end

		for _, s in pairs(RLSettings.SETTINGS) do
			if s.dependancy and s.dependancy.name == self.setting and s.element ~= nil then
				s.element:setDisabled(s.dependancy.state ~= state)
			end
		end

        if g_server ~= nil then RLSettings.saveToXMLFile() end

    end

end


function RL_BroadcastSettingsEvent.sendEvent(setting)
	if g_server ~= nil then
		g_server:broadcastEvent(RL_BroadcastSettingsEvent.new(setting))
	else
		g_client:getServerConnection():sendEvent(RL_BroadcastSettingsEvent.new(setting))
	end
end