AIBulkMessageEvent = {}

local AIBulkMessageEvent_mt = Class(AIBulkMessageEvent, Event)
InitEventClass(AIBulkMessageEvent, "AIBulkMessageEvent")


function AIBulkMessageEvent.emptyNew()

    local self = Event.new(AIBulkMessageEvent_mt)
    return self

end


function AIBulkMessageEvent.new(object, messages)

	local event = AIBulkMessageEvent.emptyNew()

	event.object = object
	event.messages = messages

	return event

end


function AIBulkMessageEvent:readStream(streamId, connection)

	self.object = NetworkUtil.readNodeObject(streamId)
	local numMessages = streamReadUInt16(streamId)

	self.messages = {}

	for i = 1, numMessages do

		local id = streamReadString(streamId)
		local numArgs = streamReadUInt8(streamId)
		local args = {}

		for j = 1, numArgs do table.insert(args, streamReadString(streamId)) end

		table.insert(self.messages, {
			["id"] = id,
			["args"] = args
		})

	end

	self:run(connection)

end


function AIBulkMessageEvent:writeStream(streamId, connection)

	NetworkUtil.writeNodeObject(streamId, self.object)

	streamWriteUInt16(streamId, #self.messages)

	for i = 1, #self.messages do

		local message = self.messages[i]
		message.args = message.args or {}

		streamWriteString(streamId, message.id)
		streamWriteUInt8(streamId, #message.args)

		for j = 1, #message.args do streamWriteString(streamId, message.args[j]) end

	end

end


function AIBulkMessageEvent:run(connection)

	for i = 1, #self.messages do

		local message = self.messages[i]
		self.object:addRLMessage(message.id, nil, message.args)

	end

end