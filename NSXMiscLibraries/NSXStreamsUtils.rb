
# encoding: UTF-8

require 'fileutils'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'json'

require 'find'

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

# ----------------------------------------------------------------------

class NSXStreamsUtils

    # -----------------------------------------------------------------
    # Utils

    # NSXStreamsUtils::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # NSXStreamsUtils::newItemFilenameToFilepath(filename)
    def self.newItemFilenameToFilepath(filename)
        frg1 = filename[0,4]
        frg2 = filename[0,6]
        frg3 = filename[0,8]
        folder1 = "/Galaxy/DataBank/Catalyst/Streams/#{frg1}/#{frg2}/#{frg3}"
        folder2 = LucilleCore::indexsubfolderpath(folder1)
        filepath = "#{folder2}/#{filename}"
        filepath
    end

    # -----------------------------------------------------------------
    # IO

    # NSXStreamsUtils::resolveFilenameToFilepathOrNullUseTheForce(filename)
    def self.resolveFilenameToFilepathOrNullUseTheForce(filename)
        Find.find("/Galaxy/DataBank/Catalyst/Streams") do |path|
            next if !File.file?(path)
            next if File.basename(path) != filename
            return path
        end
        nil
    end

    # NSXStreamsUtils::resolveFilenameToFilepathOrNull(filename)
    def self.resolveFilenameToFilepathOrNull(filename)
        filepath = KeyValueStore::getOrNull(nil, "53f8f305-38e6-4767-a312-45b2f1b059ec:#{filename}")
        if filepath then
            if File.exists?(filepath) then
                return filepath
            end
        end
        filepath = NSXStreamsUtils::resolveFilenameToFilepathOrNullUseTheForce(filename)
        if filepath then
            KeyValueStore::set(nil, "53f8f305-38e6-4767-a312-45b2f1b059ec:#{filename}", filepath)
        end
        filepath
    end

    # NSXStreamsUtils::sendItemToDisk(item)
    def self.sendItemToDisk(item)
        filepath = NSXStreamsUtils::resolveFilenameToFilepathOrNull(item["filename"])
        if filepath.nil? then
            filepath = NSXStreamsUtils::newItemFilenameToFilepath(item["filename"])
        end
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NSXStreamsUtils::allStreamsItemsEnumerator()
    def self.allStreamsItemsEnumerator()
        Enumerator.new do |items|
            Find.find("/Galaxy/DataBank/Catalyst/Streams") do |path|
                next if !File.file?(path)
                next if !File.basename(path).include?('.StreamItem.json')
                items << JSON.parse(IO.read(path))
            end
        end
    end

    # NSXStreamsUtils::getStreamItemByUUIDOrNull(streamItemUUID)
    def self.getStreamItemByUUIDOrNull(streamItemUUID)
        NSXStreamsUtils::allStreamsItemsEnumerator()
        .select{|item|
            item["uuid"] == streamItemUUID
        }
        .first
    end

    # NSXStreamsUtils::getStreamItemsOrdered(streamUUID)
    def self.getStreamItemsOrdered(streamUUID)
        NSXStreamsUtils::allStreamsItemsEnumerator()
            .select{|item| item["streamuuid"]==streamUUID }
            .sort{|i1,i2| i1["ordinal"]<=>i2["ordinal"] }
    end

    # -----------------------------------------------------------------
    # Data Processing

    # NSXStreamsUtils::makeItem(streamUUID, genericContentFilename, ordinal)
    def self.makeItem(streamUUID, genericContentFilename, ordinal)
        item = {}
        item["uuid"]                     = SecureRandom.hex
        item["streamuuid"]               = streamUUID
        item["filename"]                 = "#{NSXStreamsUtils::timeStringL22()}.StreamItem.json"
        item["generic-content-filename"] = genericContentFilename        
        item["ordinal"]                  = ordinal
        item
    end

    # NSXStreamsUtils::issueItem(streamUUID, genericContentFilename, ordinal)
    def self.issueItem(streamUUID, genericContentFilename, ordinal)
        item = NSXStreamsUtils::makeItem(streamUUID, genericContentFilename, ordinal)
        NSXStreamsUtils::sendItemToDisk(item)
        item
    end

    # NSXStreamsUtils::issueItemAtNextOrdinal(streamUUID, genericContentFilename)
    def self.issueItemAtNextOrdinal(streamUUID, genericContentFilename)
        ordinal = NSXStreamsUtils::getNextOrdinalForStream(streamUUID)
        NSXStreamsUtils::issueItem(streamUUID, genericContentFilename, ordinal)
    end

    # NSXStreamsUtils::issueItemAtNextOrdinalUsingGenericContentsItem(streamUUID, genericItem)
    def self.issueItemAtNextOrdinalUsingGenericContentsItem(streamUUID, genericItem)
        genericContentFilename = genericItem["filename"]
        NSXStreamsUtils::issueItemAtNextOrdinal(streamUUID, genericContentFilename)
    end

    # NSXStreamsUtils::getNextOrdinalForStream(streamUUID)
    def self.getNextOrdinalForStream(streamUUID)
        items = NSXStreamsUtils::getStreamItemsOrdered(streamUUID)
        return 1 if items.size==0
        items.map{|item| item["ordinal"] }.max + 1
    end

    # -----------------------------------------------------------------
    # Catalyst Objects and Commands

    # NSXStreamsUtils::streamItemToStreamCatalystObjectAnnounce(lightThread, item)
    def self.streamItemToStreamCatalystObjectAnnounce(lightThread, item)
        genericContentFilename = item["generic-content-filename"]
        genericContentsAnnounce = NSXGenericContents::filenameToCatalystObjectAnnounce(genericContentFilename)
        objectuuid = item["uuid"][0,8]
        datetime = NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(objectuuid)
        doNotShowString = 
            if datetime then
                "[DoNotShowUntil: #{datetime}]"
            else
                ""
            end
        "[LightThreadStreamItem: #{lightThread["description"]}] #{genericContentsAnnounce} #{doNotShowString}"
    end

    # NSXStreamsUtils::streamItemToStreamCatalystObjectMetric(lightThread, item, baseMetric)
    def self.streamItemToStreamCatalystObjectMetric(lightThread, item, baseMetric)
        return (2 + NSXMiscUtils::traceToMetricShift(item["uuid"]) ) if item["run-status"]
        baseMetric + Math.exp(-item["ordinal"].to_f/1000).to_f/1000
    end

    # NSXStreamsUtils::streamItemToStreamCatalystObjectCommands(item)
    def self.streamItemToStreamCatalystObjectCommands(item)
        isRunning = !item["run-status"].nil?
        if isRunning then
            ["open", "stop", "done", "numbers", "recast"]
        else
            ["start", "done", "numbers", "recast"]
        end
    end

    # NSXStreamsUtils::streamItemToStreamCatalystObject(lightThread, item, baseMetric)
    def self.streamItemToStreamCatalystObject(lightThread, item, baseMetric)
        genericContentsItemOrNull = lambda{|genericContentFilename|
            filepath = NSXGenericContents::resolveFilenameToFilepathOrNull(genericContentFilename)
            return nil if filepath.nil?
            JSON.parse(IO.read(filepath)) 
        }
        isRunning = !item["run-status"].nil?
        object = {}
        object["uuid"] = item["uuid"][0,8]      
        object["agent-uid"] = "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1"  
        object["metric"] = NSXStreamsUtils::streamItemToStreamCatalystObjectMetric(lightThread, item, baseMetric)
        object["announce"] = NSXStreamsUtils::streamItemToStreamCatalystObjectAnnounce(lightThread, item)
        object["commands"] = NSXStreamsUtils::streamItemToStreamCatalystObjectCommands(item)
        object["default-expression"] = nil
        object["is-running"] = isRunning
        object["data"] = {}
        object["data"]["stream-item"] = item
        object["data"]["generic-contents-item"] = genericContentsItemOrNull.call(item["generic-content-filename"]) 
        object["data"]["light-thread"] = lightThread
        object
    end

    # NSXStreamsUtils::viewItem(filename)
    def self.viewItem(filename)
        filepath = NSXStreamsUtils::resolveFilenameToFilepathOrNull(filename)
        if filepath.nil? then
            puts "Error fbc5372e: unknown file" 
            LucilleCore::pressEnterToContinue()
            return
        end
        streamItem = JSON.parse(IO.read(filepath))
        NSXGenericContents::viewItem(streamItem["generic-content-filename"])
    end

    # NSXStreamsUtils::destroyItem(filename)
    def self.destroyItem(filename)
        filepath = NSXStreamsUtils::resolveFilenameToFilepathOrNull(filename)
        if filepath.nil? then
            puts "Error 316492ca: unknown file (#{filename})" 
            LucilleCore::pressEnterToContinue()
        end
        item = JSON.parse(IO.read(filepath))
        NSXGenericContents::destroyItem(item["generic-content-filename"])
        NSXMiscUtils::moveLocationToCatalystBin(filepath)
    end

    # NSXStreamsUtils::startStreamItem(streamItemUUID)
    def self.startStreamItem(streamItemUUID)
        item = NSXStreamsUtils::getStreamItemByUUIDOrNull(streamItemUUID)
        return if item.nil?
        return if item["run-status"] # already running
        item["run-status"] = Time.new.to_i
        NSXStreamsUtils::sendItemToDisk(item)
    end

    # NSXStreamsUtils::stopStreamItem(streamItemUUID): # timespan
    def self.stopStreamItem(streamItemUUID) # timespan
        item = NSXStreamsUtils::getStreamItemByUUIDOrNull(streamItemUUID)
        return 0 if item.nil?
        return 0 if !item["run-status"] # not running
        timespan = Time.new.to_i - item["run-status"]
        streamItemRunTimeData = [ Time.new.to_i, timespan ]
        item["run-status"] = nil
        if item["run-data"].nil? then
            item["run-data"] = []
        end
        item["run-data"] << streamItemRunTimeData
        NSXStreamsUtils::sendItemToDisk(item)
        timespan
    end

    # NSXStreamsUtils::stopPostProcessing(streamItemUUID)
    def self.stopPostProcessing(streamItemUUID)
        item = NSXStreamsUtils::getStreamItemByUUIDOrNull(streamItemUUID)
        return if item.nil?
        if item["run-data"].nil? then
            item["run-data"] = []
        end
        totalProcessingTimeInSeconds = item["run-data"].map{|x| x[1] }.inject(0, :+)
        if totalProcessingTimeInSeconds >= 3600 then
            # Here we update the oridinal or the object to be the new object in position 5
            item["ordinal"] = NSXStreamsUtils::newPosition5OrdinalForXStreamItem(streamItemUUID)
            item["run-data"] = []
            NSXStreamsUtils::sendItemToDisk(item)
        end
    end

    # -----------------------------------------------------------------
    # User Interface    

    # NSXStreamsUtils::pickUpXStreamDropOff()
    def self.pickUpXStreamDropOff()
        Dir.entries("/Users/pascal/Desktop/XStream-DropOff")
        .select{|filename| filename[0,1]!="." }
        .map{|filename| "/Users/pascal/Desktop/XStream-DropOff/#{filename}" }
        .map{|location|
            genericItem = NSXGenericContents::issueItemLocationMoveOriginal(location)
            NSXStreamsUtils::issueItemAtNextOrdinalUsingGenericContentsItem(NSXStreamsUtils::streamOldNameToStreamUUID("XStream"), genericItem)
        }
    end

    # -----------------------------------------------------------------
    # Special Circumstances

    # NSXStreamsUtils::newPosition5OrdinalForXStreamItem(streamItemUUID)
    def self.newPosition5OrdinalForXStreamItem(streamItemUUID)
        items = NSXStreamsUtils::getStreamItemsOrdered(NSXStreamsUtils::streamOldNameToStreamUUID("XStream"))
        # first we remove the item from the stream
        items = items.reject{|item| item["uuid"]==streamItemUUID }
        if item.size == 0 then
            return 1 # There was only one item (or zero) in the stream and we default to 1
        end 
        if items.size <= 4 then
            return items.last["ordinal"] + 1
        end
        return ( items[3]["ordinal"] + items[4]["ordinal"] ).to_f/2 # Average of the 4th item and the 5th item ordinals
    end

    # NSXStreamsUtils::newLastPositionOrdinalForXStream()
    def self.newLastPositionOrdinalForXStream()
        items = NSXStreamsUtils::getStreamItemsOrdered(NSXStreamsUtils::streamOldNameToStreamUUID("XStream"))
        return 1 if items.size == 0
        items.map{|item| item["ordinal"] }.max + 1
    end

    # NSXStreamsUtils::newFrontPositionOrdinalForXStream()
    def self.newFrontPositionOrdinalForXStream()
        items = NSXStreamsUtils::getStreamItemsOrdered(NSXStreamsUtils::streamOldNameToStreamUUID("XStream"))
        return 1 if items.size == 0
        items.map{|item| item["ordinal"] }.min - 1
    end

    # NSXStreamsUtils::moveToXStreamAtOrdinal(streamItemUUID, ordinal)
    def self.moveToXStreamAtOrdinal(streamItemUUID, ordinal)
        item = NSXStreamsUtils::getStreamItemByUUIDOrNull(streamItemUUID)
        return if item.nil?
        item["streamuuid"] = NSXStreamsUtils::streamOldNameToStreamUUID("XStream")
        item["ordinal"] = ordinal
        NSXStreamsUtils::sendItemToDisk(item)
    end

    # NSXStreamsUtils::oldStreamNamesToNewStreamUUIDMapping()
    def self.oldStreamNamesToNewStreamUUIDMapping()
        {
            "Right-Now"       => "29be9b439c40a9e8fcd34b7818ba4153",
            "Today-Important" => "03b79978bcf7a712953c5543a9df9047",
            "XStream"         => "354d0160d6151cb10015e6325ca5f26a"
        }
    end

    # NSXStreamsUtils::streamOldNameToStreamUUID(streamName)
    def self.streamOldNameToStreamUUID(streamName)
        NSXStreamsUtils::oldStreamNamesToNewStreamUUIDMapping()[streamName]
    end

end
