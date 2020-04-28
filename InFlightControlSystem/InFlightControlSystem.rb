# encoding: UTF-8

# require_relative "../InFlightControlSystem/InFlightControlSystem.rb"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)

    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/DoNotShowUntil.rb"
#    DoNotShowUntil::setUnixtime(uid, unixtime)
#    DoNotShowUntil::isVisible(uid)

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

require_relative "../Catalyst-Common/Catalyst-Common.rb"

# -----------------------------------------------------------------

=begin

{
    "uuid"            : String
    "targetuuid"      : String
    "description"     : String
    "position"        : Float
    "filepath"        : String # automatically computed at retrieval time, helps with the deletion of the item
}

The item that stands for doing down the todo list

{
  "uuid": "0cd815de-b65b-44de-a130-149db5c260b6",
  "targetuuid": null,
  "description": "🛩️",
  "position": 0
}


=end

class InFlightControlSystem

    # InFlightControlSystem::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # -----------------------------------------------------------
    # Making

    # Presents the current priority list of the caller and let them enter a number that is then returned
    # InFlightControlSystem::interactiveChoiceOfPosition()
    def self.interactiveChoiceOfPosition() # Float
        puts "Items"
        InFlightControlSystem::itemsOrderedByPosition()
            .each{|item|
                puts "    - #{item["position"]} #{item["description"]}"
            }
        position = LucilleCore::askQuestionAnswerAsString("position (must be at least 1): ").to_f
        if position < 1 then
            return InFlightControlSystem::interactiveChoiceOfPosition()
        end
        position
    end

    # Creates a new entry in the tracking repository
    # InFlightControlSystem::newItem(targetuuid, description, position)
    def self.newItem(targetuuid, description, position)
        item = {
            "uuid"            => SecureRandom.uuid,
            "targetuuid"      => targetuuid,
            "description"     => description,
            "position"        => position
        }
        filename = "/Users/pascal/Galaxy/DataBank/Catalyst/InFlightControlSystem/#{InFlightControlSystem::timeStringL22()}.json"
        File.open(filename, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # InFlightControlSystem::newItemInteractive(targetuuid, description)
    def self.newItemInteractive(targetuuid, description)
        position = InFlightControlSystem::interactiveChoiceOfPosition()
        InFlightControlSystem::newItem(targetuuid, description, position)
    end

    # -----------------------------------------------------------
    # 

    # InFlightControlSystem::itemsOrderedByPosition()
    def self.itemsOrderedByPosition()
        Dir.entries("/Users/pascal/Galaxy/DataBank/Catalyst/InFlightControlSystem")
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "/Users/pascal/Galaxy/DataBank/Catalyst/InFlightControlSystem/#{filename}" }
            .map{|filepath| 
                item = JSON.parse(IO.read(filepath))
                item["filepath"] = filepath
                item
            }
            .sort{|i1, i2| i1["position"] <=> i2["position"] }
    end

    # InFlightControlSystem::isTopThree(targetuuid)
    def self.isTopThree(targetuuid) # Boolean
        InFlightControlSystem::itemsOrderedByPosition()
            .first(3)
            .any?{|item| item["targetuuid"] == targetuuid }
    end

    # InFlightControlSystem::isRegistered(targetuuid)
    def self.isRegistered(targetuuid) # Boolean
        InFlightControlSystem::itemsOrderedByPosition()
            .any?{|item| item["targetuuid"] == targetuuid }
    end

    # InFlightControlSystem::destroyItem(targetuuid)
    def self.destroyItem(targetuuid)
        InFlightControlSystem::itemsOrderedByPosition()
            .select{|item| item["targetuuid"] == targetuuid }
            .each{|item|
                FileUtils.rm(item["filepath"])
            }
    end

    # -----------------------------------------------------------
    #

    # InFlightControlSystem::getTopThree()
    def self.getTopThree()
        InFlightControlSystem::itemsOrderedByPosition()
            .first(3)
    end

    # InFlightControlSystem::getTopThreeTrace()
    def self.getTopThreeTrace()
        InFlightControlSystem::itemsOrderedByPosition()
            .first(3)
            .map{|item| item["uuid"] }
            .join("/")
    end

    # InFlightControlSystem::isRunning(targetuuid)
    def self.isRunning(targetuuid)
        unixtime = KeyValueStore::getOrNull(nil, "#{InFlightControlSystem::getTopThreeTrace()}:b5a151ef-515e-403e-9313-1c9c463052d1:#{targetuuid}")
        !unixtime.nil?
    end

    # InFlightControlSystem::start(targetuuid)
    def self.start(targetuuid)
        return if InFlightControlSystem::isRunning(targetuuid)
        KeyValueStore::set(nil, "#{InFlightControlSystem::getTopThreeTrace()}:b5a151ef-515e-403e-9313-1c9c463052d1:#{targetuuid}", Time.new.to_i)
    end

    # InFlightControlSystem::stop(targetuuid)
    def self.stop(targetuuid) # Float or Null # latter if it wasn't running.
        return if !InFlightControlSystem::isRunning(targetuuid)
        unixtime = KeyValueStore::getOrNull(nil, "#{InFlightControlSystem::getTopThreeTrace()}:b5a151ef-515e-403e-9313-1c9c463052d1:#{targetuuid}").to_i
        KeyValueStore::destroy(nil, "#{InFlightControlSystem::getTopThreeTrace()}:b5a151ef-515e-403e-9313-1c9c463052d1:#{targetuuid}")
        timespan = Time.new.to_i - unixtime
        Mercury::postValue("#{InFlightControlSystem::getTopThreeTrace()}:7ee6b697-ced5-4b43-8724-405d9e744971:#{targetuuid}", timespan)
    end

    # InFlightControlSystem::runTimeInSecondsOrNull(targetuuid)
    def self.runTimeInSecondsOrNull(targetuuid)
        unixtime = KeyValueStore::getOrNull(nil, "#{InFlightControlSystem::getTopThreeTrace()}:b5a151ef-515e-403e-9313-1c9c463052d1:#{targetuuid}")
        return nil if unixtime.nil?
        Time.new.to_i - unixtime.to_i
    end

    # InFlightControlSystem::targetTimePoints(targetuuid)
    def self.targetTimePoints(targetuuid)
        Mercury::getAllValues("#{InFlightControlSystem::getTopThreeTrace()}:7ee6b697-ced5-4b43-8724-405d9e744971:#{targetuuid}")
    end

    # InFlightControlSystem::targetStoredTotalTimespan(targetuuid)
    def self.targetStoredTotalTimespan(targetuuid)
        InFlightControlSystem::targetTimePoints(targetuuid).inject(0, :+)
    end

    # InFlightControlSystem::targetLiveTotalTimespan(targetuuid)
    def self.targetLiveTotalTimespan(targetuuid)
        x0 = InFlightControlSystem::targetStoredTotalTimespan(targetuuid)
        x1 = 0
        unixtime = KeyValueStore::getOrNull(nil, "#{InFlightControlSystem::getTopThreeTrace()}:b5a151ef-515e-403e-9313-1c9c463052d1:#{targetuuid}")
        if unixtime then
            x1 = Time.new.to_i - unixtime.to_i
        end
        x0 + x1
    end

    # -----------------------------------------------------------
    #

    # null if not registered or not top three
    # InFlightControlSystem::differentialInSecondsOrNull(targetuuid)
    def self.differentialInSecondsOrNull(targetuuid)
        # First, we get the top three
        topThree = InFlightControlSystem::getTopThree()
        return nil if topThree.none?{|item| item["targetuuid"] == targetuuid }
        theFocus    = topThree.select{|item| item["targetuuid"] == targetuuid }
        theOtherTwo = topThree.reject{|item| item["targetuuid"] == targetuuid }
        return nil if theOtherTwo.empty?
        InFlightControlSystem::targetLiveTotalTimespan(theFocus) - theOtherTwo.map{|item| InFlightControlSystem::targetLiveTotalTimespan(item) }.min
    end

    # InFlightControlSystem::isMostLate(targetuuid)
    def self.isMostLate(targetuuid) # Boolean
        return false if !InFlightControlSystem::isTopThree(targetuuid)
        return true  if InFlightControlSystem::isTopThree(targetuuid) and InFlightControlSystem::getTopThree().size == 1 # We only have the dive item
        return false if InFlightControlSystem::differentialInSecondsOrNull(targetuuid) > 0
        true
    end

    # -----------------------------------------------------------
    #

    # InFlightControlSystem::metricOrNull(targetuuid)
    def self.metricOrNull(targetuuid)
        return 1 if InFlightControlSystem::isRunning(targetuuid)
        return 0.75 if ( InFlightControlSystem::isTopThree(targetuuid) and InFlightControlSystem::isMostLate(targetuuid) )
        return 0.30 if ( InFlightControlSystem::isTopThree(targetuuid) and !InFlightControlSystem::isMostLate(targetuuid) )
        return 0.25 if ( InFlightControlSystem::isRegistered(targetuuid) and !InFlightControlSystem::isTopThree(targetuuid) )
        nil
    end

end
