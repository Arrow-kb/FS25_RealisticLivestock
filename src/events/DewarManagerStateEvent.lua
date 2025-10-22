DewarManagerStateEvent = {}

local DewarManagerStateEvent_mt = Class(DewarManagerStateEvent, Event)
InitEventClass(DewarManagerStateEvent, "DewarManagerStateEvent")


function DewarManagerStateEvent.emptyNew()

    local self = Event.new(DewarManagerStateEvent_mt)
    return self

end


function DewarManagerStateEvent.new()

	local event = DewarManagerStateEvent.emptyNew()

	return event

end


function DewarManagerStateEvent:readStream(streamId, connection)

	g_dewarManager:readStream(streamId, connection)

	self:run(connection)

end


function DewarManagerStateEvent:writeStream(streamId, connection)

	g_dewarManager:writeStream(streamId, connection)

end


function DewarManagerStateEvent:run(connection)



end