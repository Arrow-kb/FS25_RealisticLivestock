HusbandryMessageStateEvent = {}

local HusbandryMessageStateEvent_mt = Class(HusbandryMessageStateEvent, Event)
InitEventClass(HusbandryMessageStateEvent, "HusbandryMessageStateEvent")


function HusbandryMessageStateEvent.emptyNew()

    local self = Event.new(HusbandryMessageStateEvent_mt)
    return self

end


function HusbandryMessageStateEvent.new(husbandries)

	local event = HusbandryMessageStateEvent.emptyNew()

	event.husbandries = husbandries

	return event

end


function HusbandryMessageStateEvent:readStream(streamId, connection)

	local numHusbandries = streamReadUInt8(streamId)

	for i = 1, numHusbandries do

		local husbandry = NetworkUtil.readNodeObject(streamId)

		local hasUnreadMessages = streamReadBool(streamId)
		local nextUniqueId = streamReadUInt16(streamId)
		husbandry:setHasUnreadRLMessages(hasUnreadMessages)
		husbandry:setNextRLMessageUniqueId(nextUniqueId)

		local numMessages = streamReadUInt16(streamId)
		local messages = {}

		for j = 1, numMessages do
			
			local id = streamReadString(streamId)
			local date = streamReadString(streamId)
			local uniqueId = streamReadUInt16(streamId)

			local message = {
				["id"] = id,
				["date"] = date,
				["uniqueId"] = uniqueId,
				["args"] = {}
			}

			local hasAnimal = streamReadBool(streamId)

			if hasAnimal then message.animal = streamReadString(streamId) end

			local numArgs = streamReadUInt8(streamId)
			for k = 1, numArgs do table.insert(message.args, streamReadString(streamId)) end

			table.insert(messages, message)

		end

		husbandry.spec_husbandryAnimals.messages = messages

	end

end


function HusbandryMessageStateEvent:writeStream(streamId, connection)

	streamWriteUInt8(streamId, #self.husbandries)

	for _, husbandry in pairs(self.husbandries) do

		NetworkUtil.writeNodeObject(streamId, husbandry)
		streamWriteBool(streamId, husbandry:getHasUnreadRLMessages())
		streamWriteUInt16(streamId, husbandry:getNextRLMessageUniqueId())

		local messages = husbandry:getRLMessages()
		streamWriteUInt16(streamId, #messages)

		for i = 1, #messages do

			local message = messages[i]

			streamWriteString(streamId, message.id)
			streamWriteString(streamId, message.date)
			streamWriteUInt16(streamId, message.uniqueId)

			streamWriteBool(streamId, message.animal ~= nil)

			if message.animal ~= nil then streamWriteString(streamId, message.animal) end

			streamWriteUInt8(streamId, #message.args)

			for j = 1, #message.args do streamWriteString(streamId, message.args[j]) end

		end

	end

end