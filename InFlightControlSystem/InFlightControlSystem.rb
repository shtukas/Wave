#!/Users/pascal/.rvm/rubies/ruby-2.5.1/bin/ruby
# encoding: UTF-8

require 'colorize'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/Mercury.rb"
=begin
    Mercury::postValue(channel, value)
    Mercury::dequeueFirstValueOrNull(channel)

    Mercury::discardFirstElementsToEnforeQueueSize(channel, size)
    Mercury::discardFirstElementsToEnforceTimeHorizon(channel, unixtime)

    Mercury::getQueueSize(channel)
    Mercury::getAllValues(channel)

    Mercury::getFirstValueOrNull(channel)
    Mercury::deleteFirstValue(channel)
=end

# --------------------------------------------------------------------

=begin

Item {
    "uuid"                    : String,
    "lucilleLocationBasename" : String
    "position"                : Float
    "DoNotShowUntilUnixtime"  : Unixtime # Optional
}

TimePoints : Array[TimePoint]

TimePoint = {
    "unixtime" : Float
    "timespan" : Float
}

=end

# --------------------------------------------------------------------

# ---------------
# IO Items

def waveuuid()
    "f1e7bf19-ef85-4e93-a904-6287dbc8ad4e"
end

def waveItem()
    {
        "uuid" => waveuuid(),
        "lucilleLocationBasename" => nil,
        "position" => 0
    }
end

def itemIsWave(item)
    item["uuid"] == waveuuid()
end

def itemsFolderpath()
    "/Users/pascal/Galaxy/DataBank/Catalyst/InFlightControlSystem/items"
end

def getItemsWihtoutWave()

    # We start by doing some garbage collection
    # Removing the items which do not have a corresponding Lucille location

    if !File.exists?("/Users/pascal/Galaxy/DataBank/Catalyst/Lucille/Items") then
        raise "[IFCS error: 97d313e44785] Can't see the Lucille items folder"
    end

    # We now rename basenames if we get messages to do so
    # We have to do this BEFORE the next step

    loop {
        channel = "0b5b0b54-ea17-40f6-b3f7-d0bfaa641470-lucille-to-ifcs-rebasing"
        message = Mercury::dequeueFirstValueOrNull(channel)
        break if message.nil?
        item = getItemByBasenameOrNull(message["old"])
        break if item.nil?
        item["lucilleLocationBasename"] = message["new"]
        saveItem(item)
    }

    # Removing the items which do not have a corresponding Lucille location

    Dir.entries(itemsFolderpath())
        .select{|filename| filename[-5, 5] == ".json" }
        .map{|filename| "#{itemsFolderpath()}/#{filename}"}
        .each{|filepath|
            item = JSON.parse(IO.read(filepath))
            lucilleLocationBasename = item["lucilleLocationBasename"]
            if !File.exists?("/Users/pascal/Galaxy/DataBank/Catalyst/Lucille/Items/#{lucilleLocationBasename}") then
                FileUtils.rm(filepath)
            end
        }

    # Computing answer

    Dir.entries(itemsFolderpath())
        .select{|filename| filename[-5, 5] == ".json" }
        .map{|filename| JSON.parse(IO.read("#{itemsFolderpath()}/#{filename}")) }
end

def getItems()
    getItemsWihtoutWave() + [ waveItem() ]
end

def getTopThreeActiveItems()
    getItems()
        .select{|item| 
            b1 = item["DoNotShowUntilUnixtime"].nil? or ( Time.new.to_i > item["DoNotShowUntilUnixtime"] ) 
            b2 = itemIsRunning(item)
            b1 or b2
        }
        .sort{|i1, i2| i1["position"] <=> i2["position"] }
        .first(3)
end

def saveItem(item)
    return if item["uuid"] == waveuuid()
    uuid = item["uuid"]
    filepath = "#{itemsFolderpath()}/#{uuid}.json"
    File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
end

def getItemByUUIDOrNull(uuid)
    if uuid == waveuuid() then
        return waveItem()
    end
    filepath = "#{itemsFolderpath()}/#{uuid}.json"
    return nil if !File.exists?(filepath)
    JSON.parse(IO.read(filepath))
end

def getItemByBasenameOrNull(basename)
    Dir.entries(itemsFolderpath())
        .select{|filename| filename[-5, 5] == ".json" }
        .map{|filename| JSON.parse(IO.read("#{itemsFolderpath()}/#{filename}")) }
        .select{|item| item["lucilleLocationBasename"] == basename }
        .first
end

def destroyItem(uuid)
    return if uuid == waveuuid()
    stopItem(uuid)
    filepath = "#{itemsFolderpath()}/#{uuid}.json"
    FileUtils.rm(filepath)
end

# ---------------
# Time Points

def timePointsKeyPrefix()
    s1 = "72a74d9f-a3df-4ec3-b6b2-e6aeb197119e"
    s2 = getTopThreeActiveItems()
        .map{|item| item["uuid"] }
        .sort
        .join(";")
    [s1, s2].join(";;")
end

def getItemTimePoints(uuid)
    timepoints = KeyValueStore::getOrDefaultValue(nil, "#{timePointsKeyPrefix()}:#{uuid}", "[]")
    JSON.parse(timepoints)
end

def saveItemTimepoints(uuid, timepoints)
    KeyValueStore::set(nil, "#{timePointsKeyPrefix()}:#{uuid}", JSON.generate(timepoints))
end

# ---------------
# Run Management

def setStartUnixtime(uuid, unixtime)
    KeyValueStore::set(nil, "47d2c99f-cbcc-410a-b3c5-faa681571c7b:#{uuid}", unixtime)
end

def unsetStartUnixtime(uuid)
    KeyValueStore::destroy(nil, "47d2c99f-cbcc-410a-b3c5-faa681571c7b:#{uuid}")
end

def getStartUnixtimeOrNull(uuid)
    unixtime = KeyValueStore::getOrNull(nil, "47d2c99f-cbcc-410a-b3c5-faa681571c7b:#{uuid}")
    return nil if unixtime.nil?
    unixtime.to_i
end

def startItem(uuid)

    return if !getStartUnixtimeOrNull(uuid).nil?

    setStartUnixtime(uuid, Time.new.to_i)

    # When we start a ifcs item we also want to start the corresponding lucille item
    # But not if it's the Wave item
    return if uuid == waveuuid()
    item = getItemByUUIDOrNull(uuid)
    return if item.nil?
    system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Lucille/lucille-open-location-basename '#{item["lucilleLocationBasename"]}'")
    system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Lucille/lucille-start-location-basename '#{item["lucilleLocationBasename"]}'")
end

def stopItem(uuid)

    return if getStartUnixtimeOrNull(uuid).nil?

    timespan = [Time.new.to_i - getStartUnixtimeOrNull(uuid), 3600*2].min
        # We prevent time spans greater than 2 hours,
        # to avoid what happened when I left Wave running an entire night.
    
    timepoints = getItemTimePoints(uuid)
    timepoints << {
        "unixtime" => Time.new.to_i,
        "timespan" => timespan
    } 
    saveItemTimepoints(uuid, timepoints)

    unsetStartUnixtime(uuid)

    # When we stop a ifcs item we also want to stop the corresponding lucille item
    item = getItemByUUIDOrNull(uuid)
    return if item.nil?
    system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Lucille/lucille-stop-location-basename '#{item["lucilleLocationBasename"]}'")
end

def itemIsRunning(item)
    !getStartUnixtimeOrNull(item["uuid"]).nil?
end

# ---------------
# Operations

def itemIsTopActiveItem(uuid)
    getTopThreeActiveItems().any?{|i| i["uuid"] == uuid }
end

def getItemLiveTimespan(uuid)
    unixtime = getStartUnixtimeOrNull(uuid)
    x1 = 0
    if unixtime then
        x1 = Time.new.to_i - unixtime
    end
    x1 + getItemTimePoints(uuid).map{|point| point["timespan"] }.inject(0, :+)
end

def getItemLiveTimespanTopItemsDifferentialInHoursOrNull(uuid)
    timespan = getItemLiveTimespan(uuid)
    differentTimespans = getTopThreeActiveItems()
                            .select{|item| item["uuid"] != uuid }
                            .map {|item| getItemLiveTimespan(item["uuid"]) }
    return nil if differentTimespans.empty?
    (timespan - differentTimespans.min).to_f/3600
end

def getTopActiveItemsOrderedByTimespan()
    getTopThreeActiveItems().sort{|i1, i2| getItemLiveTimespan(i1["uuid"]) <=> getItemLiveTimespan(i2["uuid"]) }
end

def itemsOrderedByPosition()
    getItems().sort{|i1, i2| i1["position"] <=> i2["position"] }
end

# ---------------
# User Interface

def getItemDescription(item)
    return "Wave" if (item["uuid"] == waveuuid())
    location = "/Users/pascal/Galaxy/DataBank/Catalyst/Lucille/Items/#{item["lucilleLocationBasename"]}"
    KeyValueStore::getOrNull(nil, "3bbaacf8-2114-4d85-9738-0d4784d3bbb2:#{location}") || "[unkown description]"
end

def onScreenNotification(title, message)
    title = title.gsub("'","")
    message = message.gsub("'","")
    message = message.gsub("[","|")
    message = message.gsub("]","|")
    command = "terminal-notifier -title '#{title}' -message '#{message}'"
    system(command)
end

def itemDive(item)
    loop {
        puts JSON.pretty_generate(item)
        oxs = [ 
            "start", 
            "stop",
            "open",
            "set description",
            "set position",
            "suspend temporarily",
            "dive into Lucille item",
            (item["uuid"] != waveuuid()) ? "destroy" : nil
        ].compact
        ox = LucilleCore::selectEntityFromListOfEntitiesOrNull("ifcs", oxs)
        return if ox.nil?
        if ox == "start" then
            startItem(item["uuid"])
        end
        if ox == "stop" then
            stopItem(item["uuid"])
        end
        if ox == "open" then
            if item["uuid"] == waveuuid() then
                puts "It's not possible to open Wave"
                LucilleCore::pressEnterToContinue()
                next
            end
            system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Lucille/lucille-open-location-basename '#{item["lucilleLocationBasename"]}'")
        end
        if ox == "set description" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            location = "/Users/pascal/Galaxy/DataBank/Catalyst/Lucille/Items/#{item["lucilleLocationBasename"]}"
            KeyValueStore::set(nil, "3bbaacf8-2114-4d85-9738-0d4784d3bbb2:#{location}", description)
        end
        if ox == "set position" then
            item["position"] = LucilleCore::askQuestionAnswerAsString("position: ").to_f
            saveItem(item)
        end
        if ox == "suspend temporarily" then
            timespanInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
            item["DoNotShowUntilUnixtime"] = Time.new.to_i + timespanInHours*3600
            saveItem(item)
        end
        if ox == "dive into Lucille item" then
            system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Lucille/lucille-dive-location-basename '#{item["lucilleLocationBasename"]}'")
        end
        if ox == "destroy" then
            uuid = item["uuid"]
            destroyItem(uuid)
        end
    }
end
