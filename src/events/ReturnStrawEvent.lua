ReturnStrawEvent = {}

local ReturnStrawEvent_mt = Class(ReturnStrawEvent, Event)
InitEventClass(ReturnStrawEvent, "ReturnStrawEvent")


function ReturnStrawEvent.emptyNew()

    local self = Event.new(ReturnStrawEvent_mt)
    return self

end


function ReturnStrawEvent.new(object)

	local event = ReturnStrawEvent.emptyNew()

	event.object = object

	return event

end


function ReturnStrawEvent:readStream(streamId, connection)

	self.object = NetworkUtil.readNodeObject(streamId)

	self:run(connection)

end


function ReturnStrawEvent:writeStream(streamId, connection)

	NetworkUtil.writeNodeObject(streamId, self.object)

end


function ReturnStrawEvent:run(connection)

	if self.object ~= nil then self.object:changeStraws(1) end

end