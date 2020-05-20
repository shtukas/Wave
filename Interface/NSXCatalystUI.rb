# encoding: UTF-8

# This variable contains the objects of the current display.
# We use it to speed up display after some operations

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/CatalystStandardTargets.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DataPoints.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Starlight.rb"

# ------------------------------------------------------------------------

class NSXCatalystUI

    # NSXCatalystUI::performInterfaceDisplay(displayObjects)
    def self.performInterfaceDisplay(displayObjects)

        displayTime = Time.new.to_f

        system("clear")

        displayItems = []

        position = 0
        verticalSpaceLeft = NSXMiscUtils::screenHeight()-3

        puts ""
        verticalSpaceLeft = verticalSpaceLeft - 1

        opencycles = JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/OpenCycles/x-interface-datapoints`)
        opencycles.each{|datapoint|
            puts ("[#{position.to_s.rjust(3)}] [opencycle] " + DataPoints::datapointToString(datapoint)[10, 999]).yellow
            verticalSpaceLeft = verticalSpaceLeft - 1
            displayItems[position] = ["datapoint", datapoint]
            position = position + 1
        }

        content = IO.read("/Users/pascal/Galaxy/DataBank/Catalyst/Interface/Interface-Top.txt").strip
        if content.size > 0 then
            content = content.lines.select{|line| line.strip.size > 0 }.join().green
            puts ""
            puts content
            verticalSpaceLeft = verticalSpaceLeft - ( NSXDisplayUtils::verticalSize(content) + 1 )
        end

        calendarreport = `/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Calendar/calendar-report`.strip
        if calendarreport.size > 0 and (calendarreport.lines.to_a.size + 2) < verticalSpaceLeft then
            puts ""
            puts calendarreport
            verticalSpaceLeft = verticalSpaceLeft - ( calendarreport.lines.to_a.size + 1 )
        end

        puts ""
        verticalSpaceLeft = verticalSpaceLeft - 1

        firstPositionForCatalystObjects = position
        while !displayObjects[position].nil? and verticalSpaceLeft > 0 do
            object = displayObjects[position-firstPositionForCatalystObjects]
            displayItems[position] = ["catalyst-objects", object]
            displayStr = NSXDisplayUtils::objectDisplayStringForCatalystListing(object, position == firstPositionForCatalystObjects, position)
            puts displayStr
            verticalSpaceLeft = verticalSpaceLeft - NSXDisplayUtils::verticalSize(displayStr)
            position = position + 1
        end

        puts ""
        print "--> "
        command = STDIN.gets().strip
        if command=='' then
            if (Time.new.to_f - displayTime) < 5 then
                return NSXCatalystUI::performInterfaceDisplay(displayObjects)
            end
            return
        end

        if command[0,1] == "'" and  NSXMiscUtils::isInteger(command[1,999]) then
            position = command[1,999].to_i
            item = displayItems[position]
            if item[0] == "datapoint" then
                DataPoints::pointDive(item[1])
            end
            if item[0] == "catalyst-objects" then
                NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(item[1])
            end
            return
        end

        NSXGeneralCommandHandler::processCatalystCommandManager(displayObjects[0], command)
    end

    # NSXCatalystUI::importFromLucilleInbox()
    def self.importFromLucilleInbox()
        getNextLocationAtTheInboxOrNull = lambda {
            Dir.entries("/Users/pascal/Desktop/Lucille-Inbox")
                .reject{|filename| filename[0, 1] == '.' }
                .map{|filename| "/Users/pascal/Desktop/Lucille-Inbox/#{filename}" }
                .first
        }
        while (location = getNextLocationAtTheInboxOrNull.call()) do
            if File.basename(location).include?("'") then
                basename2 = File.basename(location).gsub("'", ",")
                location2 = "#{File.dirname(location)}/#{basename2}"
                FileUtils.mv(location, location2)
                next
            end
            target = CatalystStandardTargets::locationToFileOrFolderTarget(location)
            item = {
                "uuid"         => SecureRandom.uuid,
                "creationtime" => Time.new.to_f,
                "projectname"  => "Inbox",
                "projectuuid"  => "44caf74675ceb79ba5cc13bafa102509369c2b53",
                "description"  => File.basename(location),
                "target"       => target
            }
            puts JSON.pretty_generate(item)
            filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Todo/items2/#{item["uuid"]}.json"
            File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(item)) }
            LucilleCore::removeFileSystemLocation(location)
        end
    end

    # NSXCatalystUI::standardUILoop()
    def self.standardUILoop()
        loop {
            if STARTING_CODE_HASH != NSXEstateServices::locationHashRecursively(CATALYST_CODE_FOLDERPATH) then
                puts "Code change detected. Exiting."
                return
            end
            NSXCatalystUI::importFromLucilleInbox()
            NSXCuration::curation()
            objects = NSXCatalystObjectsOperator::getCatalystListingObjectsOrdered()
            NSXCatalystUI::performInterfaceDisplay(objects)
        }
    end
end


