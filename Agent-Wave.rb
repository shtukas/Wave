#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require 'json'
require 'date'
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv('oldname', 'newname')
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')
require 'find'
require 'drb/drb'
require "/Galaxy/LucilleOS/Librarian/Librarian-Exported-Functions.rb"
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"

require_relative "Constants.rb"
require_relative "Events.rb"
require_relative "Flock.rb"
require_relative "Events.rb"
require_relative "FKVStore.rb"
require_relative "MiniFIFOQ.rb"
require_relative "Config.rb"
require_relative "AgentsManager.rb"
require_relative "RequirementsOperator.rb"
require_relative "TodayOrNotToday.rb"
require_relative "GenericTimeTracking.rb"
require_relative "CatalystDevOps.rb"
require_relative "CollectionsOperator.rb"
require_relative "NotGuardian"
require_relative "FolderProbe.rb"
require_relative "CommonsUtils"
# ----------------------------------------------------------------------

WAVE_DATABANK_WAVE_FOLDER_PATH = "#{CATALYST_COMMON_DATABANK_FOLDERPATH}/Agents-Data/Wave"
WAVE_DROPOFF_FOLDERPATH = "/Users/pascal/Desktop/Wave-DropOff"

# ----------------------------------------------------------------------

# WaveSchedules::makeScheduleObjectTypeNew()
# WaveSchedules::makeScheduleObjectInteractivelyEnsureChoice()
# WaveSchedules::scheduleToAnnounce(schedule)
# WaveSchedules::scheduleOfTypeDateIsInTheFuture(schedule)
# WaveSchedules::cycleSchedule(schedule)
# WaveSchedules::scheduleToMetric(schedule)

class WaveSchedules

    def self.makeScheduleObjectTypeNew()
        {
            "uuid" => SecureRandom.hex,
            "type" => "schedule-7da672d1-6e30-4af8-a641-e4760c3963e6",
            "@"    => "new",
            "unixtime" => Time.new.to_i
        }
    end

    def self.makeScheduleObjectInteractivelyEnsureChoice()

        scheduleTypes = ['new', 'today', 'sticky', 'date', 'repeat']
        scheduleType = LucilleCore::interactivelySelectEntityFromListOfEntities_EnsureChoice("schedule type: ", scheduleTypes, lambda{|entity| entity })

        schedule = nil
        if scheduleType=='new' then
            schedule = {
                "uuid" => SecureRandom.hex,
                "type" => "schedule-7da672d1-6e30-4af8-a641-e4760c3963e6",
                "@"    => "new",
                "unixtime" => Time.new.to_i
            }
        end
        if scheduleType=='today' then
            schedule = {
                "uuid" => SecureRandom.hex,
                "type" => "schedule-7da672d1-6e30-4af8-a641-e4760c3963e6",
                "@"    => "today",
                "unixtime" => Time.new.to_i
            }
        end
        if scheduleType=='sticky' then
            schedule = {
                "uuid" => SecureRandom.hex,
                "type" => "schedule-7da672d1-6e30-4af8-a641-e4760c3963e6",
                "@"    => "sticky"
            }
        end
        if scheduleType=='date' then
            puts "date:"
            puts "    format: YYYY-MM-DD"
            puts "    format: +<integer, nb of days>"
            print "> "
            date = STDIN.gets().strip
            if date[0, 1] == '+' then
                shift = date[1,99].to_i
                date = (DateTime.now+shift).to_date.to_s
            end
            schedule = {
                "uuid" => SecureRandom.hex,
                "type" => "schedule-7da672d1-6e30-4af8-a641-e4760c3963e6",
                "@"    => "ondate",
                "date" => date
            }
        end
        if scheduleType=='repeat' then

            repeat_types = ['every-n-hours','every-n-days','every-this-day-of-the-week','every-this-day-of-the-month']
            type = LucilleCore::interactivelySelectEntityFromListOfEntities_EnsureChoice("repeat type: ", repeat_types, lambda{|entity| entity })

            if type=='every-n-hours' then
                print "period (in hours): "
                value = STDIN.gets().strip.to_f
            end
            if type=='every-n-days' then
                print "period (in days): "
                value = STDIN.gets().strip.to_f
            end
            if type=='every-this-day-of-the-month' then
                print "day number (String, length 2): "
                value = STDIN.gets().strip
            end
            if type=='every-this-day-of-the-week' then
                weekdays = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday']
                value = LucilleCore::interactivelySelectEntityFromListOfEntities_EnsureChoice("weekday: ", weekdays, lambda{|entity| entity })
            end
            schedule = {
                "uuid" => SecureRandom.hex,
                "type" => "schedule-7da672d1-6e30-4af8-a641-e4760c3963e6",
                "@"    => type,
                "repeat-value" => value
            }
        end
        schedule
    end

    def self.scheduleToAnnounce(schedule)

        if schedule['@'] == 'new' then
            return "new"
        end
        if schedule['@'] == 'today' then
            return "today"
        end
        if schedule['@'] == 'sticky' then
            return "sticky"
        end
        if schedule['@'] == 'ondate' then
            return "ondate: #{schedule['date']}"
        end
        if schedule['@'] == 'every-n-hours' then
            return "every-n-hours: #{schedule['repeat-value']}"
        end
        if schedule['@'] == 'every-n-days' then
            return "every-n-days: #{schedule['repeat-value']}"
        end
        if schedule['@'] == 'every-this-day-of-the-month' then
            return "every-this-day-of-the-month: #{schedule['repeat-value']}"
        end
        if schedule['@'] == 'every-this-day-of-the-week' then
            return "every-this-day-of-the-week: #{schedule['repeat-value']}"
        end

        JSON.generate(schedule)
    end

    def self.scheduleOfTypeDateIsInTheFuture(schedule)
        schedule['date'] > DateTime.now.to_date.to_s
    end

    def self.cycleSchedule(schedule)
        if schedule['@'] == 'sticky' then
            schedule["do-not-show-until-datetime"] = LucilleCore::datetimeAtComingMidnight()
        end
        if schedule['@'] == 'every-n-hours' then
            schedule["do-not-show-until-datetime"] = Time.at(Time.new.to_i+3600*schedule['repeat-value'].to_f).to_s
        end
        if schedule['@'] == 'every-n-days' then
            schedule["do-not-show-until-datetime"] = Time.at(Time.new.to_i+86400*schedule['repeat-value'].to_f).to_s
        end
        if schedule['@'] == 'every-this-day-of-the-month' then
            cursor = Time.new.to_i + 86400
            while Time.at(cursor).strftime("%d") != schedule['repeat-value'] do
                cursor = cursor + 3600
            end
            schedule["do-not-show-until-datetime"] = Time.at(cursor).to_s
        end
        if schedule['@'] == 'every-this-day-of-the-week' then
            mapping = ['sunday','monday','tuesday','wednesday','thursday','friday','saturday']
            cursor = Time.new.to_i + 86400
            while mapping[Time.at(cursor).wday]!=schedule['repeat-value'] do
                cursor = cursor + 3600
            end
            schedule["do-not-show-until-datetime"] = Time.at(cursor).to_s
        end
        schedule
    end

    def self.scheduleToMetric(schedule)

        # Special Circumstances

        if schedule["do-not-show-until-datetime"] and schedule["do-not-show-until-datetime"] > Time.new.to_s then
            return 0
        end

        if schedule['metric'] then
            return schedule['metric'] # set by wave emails
        end

        # One Offs

        if schedule['@'] == 'new' then
            age = schedule['unixtime'] - DateTime.parse("#{Time.new.to_s[0, 10]} 00:00:00").to_time.to_i
            # newer items (bigger age) have a lower metric
            return 0.820 + 0.010*Math.atan( -age.to_f/86400 )
        end
        if schedule['@'] == 'today' then
            return 0.8 - 0.05*Math.exp( -0.1*(Time.new.to_i-schedule['unixtime']).to_f/86400 )
        end
        if schedule['@'] == 'sticky' then # shows up once a day
            return Time.new.hour >= 6 ? 0.9 : 0
        end
        if schedule['@'] == 'ondate' then
            if WaveSchedules::scheduleOfTypeDateIsInTheFuture(schedule) then
                return 0
            else
                return 0.77
            end
        end

        # Repeats

        if schedule['@'] == 'every-this-day-of-the-month' then
            return 0.78
        end

        if schedule['@'] == 'every-this-day-of-the-week' then
            return 0.78
        end
        if schedule['@'] == 'every-n-hours' then
            return 0.78
        end
        if schedule['@'] == 'every-n-days' then
            return 0.78
        end
        1
    end
end

# WaveEmailSupport::emailUIDToCatalystUUIDOrNull(emailuid)
# WaveEmailSupport::allEmailUIDs()

class WaveEmailSupport
    def self.emailUIDToCatalystUUIDOrNull(emailuid)
        Wave::catalystUUIDsEnumerator()
            .each{|uuid|
                folderpath = Wave::catalystUUIDToItemFolderPathOrNull(uuid)
                next if folderpath.nil?
                emailuidfilepath = "#{folderpath}/email-metatada-emailuid.txt"
                next if !File.exist?(emailuidfilepath)
                next if IO.read(emailuidfilepath).strip != emailuid
                return uuid
            }
        nil
    end
    def self.allEmailUIDs()
        Wave::catalystUUIDsEnumerator()
            .map{|uuid|
                folderpath = Wave::catalystUUIDToItemFolderPathOrNull(uuid)
                if folderpath then
                    emailuidfilepath = "#{folderpath}/email-metatada-emailuid.txt"
                    if File.exist?(emailuidfilepath) then
                        IO.read(emailuidfilepath).strip
                    else
                        nil
                    end
                else
                    nil
                end
            }
            .compact
    end
end

# WaveDevOps::collectWave()

class WaveDevOps
    def self.collectWave()
        Dir.entries(WAVE_DROPOFF_FOLDERPATH)
            .select{|filename| filename[0, 1] != '.' }
            .map{|filename| "#{WAVE_DROPOFF_FOLDERPATH}/#{filename}" }
            .each{|sourcelocation|
                uuid = SecureRandom.hex(4)
                schedule = WaveSchedules::makeScheduleObjectTypeNew()
                folderpath = Wave::timestring22ToFolderpath(LucilleCore::timeStringL22())
                FileUtils.mkpath folderpath
                File.open("#{folderpath}/catalyst-uuid", 'w') {|f| f.write(uuid) }
                Wave::writeScheduleToDisk(uuid,schedule)
                if File.file?(sourcelocation) then
                    FileUtils.cp(sourcelocation,folderpath)
                else
                    FileUtils.cp_r(sourcelocation,folderpath)
                end
                LucilleCore::removeFileSystemLocation(sourcelocation)
            }
    end
end

# Wave::agentuuid()
# Wave::catalystUUIDToItemFolderPathOrNullUseTheForce(uuid)
# Wave::catalystUUIDToItemFolderPathOrNull(uuid)
# Wave::catalystUUIDsEnumerator()
# Wave::timestring22ToFolderpath(timestring22)
# Wave::writeScheduleToDisk(uuid,schedule)
# Wave::readScheduleFromWaveItemOrNull(uuid)
# Wave::makeNewSchedule()
# Wave::archiveWaveItem(uuid)
# Wave::commands(schedule)
# Wave::makeCatalystObjectOrNull(objectuuid)
# Wave::objectUUIDToAnnounce(object,schedule)
# Wave::removeWaveMetadataFilesAtLocation(location)
# Wave::interface()
# Wave::generalUpgrade()
# Wave::processObjectAndCommand(object, command)

class Wave

    @@firstRun = true

    def self.agentuuid()
        "283d34dd-c871-4a55-8610-31e7c762fb0d"
    end

    def self.catalystUUIDToItemFolderPathOrNullUseTheForce(uuid)
        Find.find("#{WAVE_DATABANK_WAVE_FOLDER_PATH}/OpsLine-Active") do |path|
            next if !File.file?(path)
            next if File.basename(path)!='catalyst-uuid'
            thisUUID = IO.read(path).strip
            next if thisUUID!=uuid
            return File.dirname(path)
        end
        nil
    end

    def self.catalystUUIDToItemFolderPathOrNull(uuid)
        storedValue = FKVStore::getOrNull("ed459722-ca2e-4139-a7c0-796968ef5b66:#{uuid}")
        if storedValue then
            path = JSON.parse(storedValue)[0]
            if !path.nil? then
                uuidFilepath = "#{path}/catalyst-uuid"
                if File.exist?(uuidFilepath) and IO.read(uuidFilepath).strip == uuid then
                    return path
                end
            end
        end
        #puts "Wave::catalystUUIDToItemFolderPathOrNull, looking for #{uuid}"
        maybepath = Wave::catalystUUIDToItemFolderPathOrNullUseTheForce(uuid)
        FKVStore::set("ed459722-ca2e-4139-a7c0-796968ef5b66:#{uuid}", JSON.generate([maybepath])) if maybepath
        maybepath
    end

    def self.catalystUUIDsEnumerator()
        Enumerator.new do |uuids|
            Find.find("#{WAVE_DATABANK_WAVE_FOLDER_PATH}/OpsLine-Active") do |path|
                next if !File.file?(path)
                next if File.basename(path) != 'catalyst-uuid'
                uuids << IO.read(path).strip
            end
        end
    end

    def self.timestring22ToFolderpath(timestring22) # 20170923-143534-341733
        "#{WAVE_DATABANK_WAVE_FOLDER_PATH}/OpsLine-Active/#{timestring22[0, 4]}/#{timestring22[0, 6]}/#{timestring22[0, 8]}/#{timestring22}"
    end

    def self.writeScheduleToDisk(uuid,schedule)
        folderpath = Wave::catalystUUIDToItemFolderPathOrNull(uuid)
        return if folderpath.nil?
        return if !File.exists?(folderpath)
        LucilleCore::removeFileSystemLocation("#{folderpath}/catalyst-schedule.json")
        File.open("#{folderpath}/wave-schedule.json", 'w') {|f| f.write(JSON.pretty_generate(schedule)) }
    end

    def self.readScheduleFromWaveItemOrNull(uuid)
        folderpath = Wave::catalystUUIDToItemFolderPathOrNull(uuid)
        return nil if folderpath.nil?
        filepath =
            if File.exists?("#{folderpath}/wave-schedule.json") then
                "#{folderpath}/wave-schedule.json"
            elsif File.exists?("#{folderpath}/catalyst-schedule.json") then
                "#{folderpath}/catalyst-schedule.json"
            else
                nil
            end
        return nil if filepath.nil?
        schedule = JSON.parse(IO.read(filepath))
    end

    def self.makeNewSchedule()
        WaveSchedules::makeScheduleObjectInteractivelyEnsureChoice()
    end

    def self.archiveWaveItem(uuid)
        return if uuid.nil?
        folderpath = Wave::catalystUUIDToItemFolderPathOrNull(uuid)
        return if folderpath.nil?
        retrun if !File.exists?(folderpath)
        targetFolder = CommonsUtils::newBinArchivesFolderpath()
        FileUtils.mv("#{folderpath}",targetFolder)
    end

    def self.commands(folderProbeMetadata)
        ["open", "done", "<uuid>", "recast", "description:", "folder", "destroy", ">stream", ">lib"]
    end

    def self.defaultExpression(folderProbeMetadata, schedule)
        if folderProbeMetadata["target-type"] == "openable-file" then
            return "open"
        end
        if folderProbeMetadata["target-type"] == "url" and schedule["@"] == "every-n-hours" then
            return "open done"
        end
        if folderProbeMetadata["target-type"] == "url" and schedule["@"] == "every-n-days" then
            return "open done"
        end
        if folderProbeMetadata["target-type"] == "url" and schedule["@"] == "every-this-day-of-the-month" then
            return "open done"
        end
        if folderProbeMetadata["target-type"] == "url" and schedule["@"] == "every-this-day-of-the-week" then
            return "open done"
        end 
        if folderProbeMetadata["target-type"] == "url" then
            return "open"
        end
        if folderProbeMetadata["target-type"] == "folder" then
            return "open"
        end
        if folderProbeMetadata["target-type"] == "virtually-empty-wave-folder" and schedule["@"] == "sticky" then
            return "done"
        end
        if folderProbeMetadata["target-type"] == "virtually-empty-wave-folder" and schedule["@"] == "every-n-hours" then
            return "done"
        end
        if folderProbeMetadata["target-type"] == "virtually-empty-wave-folder" and schedule["@"] == "every-n-days" then
            return "done"
        end
        if folderProbeMetadata["target-type"] == "virtually-empty-wave-folder" and schedule["@"] == "every-this-day-of-the-month" then
            return "done"
        end
        if folderProbeMetadata["target-type"] == "virtually-empty-wave-folder" and schedule["@"] == "every-this-day-of-the-week" then
            return "done"
        end
        nil
    end

    def self.objectUUIDToAnnounce(folderProbeMetadata,schedule)
        "[#{WaveSchedules::scheduleToAnnounce(schedule)}] #{folderProbeMetadata["announce"]}"
    end

    def self.removeWaveMetadataFilesAtLocation(location)
        # Removing wave files.
        Dir.entries(location)
            .select{|filename| (filename.start_with?('catalyst-') or filename.start_with?('wave-')) and !filename.include?("description") }
            .map{|filename| "#{location}/#{filename}" }
            .each{|filepath| LucilleCore::removeFileSystemLocation(filepath) }
    end

    def self.interface()
        puts "You are interfacing with Wave"
        LucilleCore::pressEnterToContinue()
    end

    def self.makeCatalystObjectOrNull(objectuuid)
        location = Wave::catalystUUIDToItemFolderPathOrNull(objectuuid)
        return nil if location.nil?
        schedule = Wave::readScheduleFromWaveItemOrNull(objectuuid)
        if schedule.nil? then
            schedule = WaveSchedules::makeScheduleObjectTypeNew()
            File.open("#{location}/wave-schedule.json", 'w') {|f| f.write(JSON.pretty_generate(schedule)) }
        end
        folderProbeMetadata = FolderProbe::folderpath2metadata(location)
        metric = WaveSchedules::scheduleToMetric(schedule)
        announce = Wave::objectUUIDToAnnounce(folderProbeMetadata, schedule)
        object = {}
        object['uuid'] = objectuuid
        object["agent-uid"] = self.agentuuid()
        object['metric'] = metric + CommonsUtils::traceToMetricShift(objectuuid)
        object['announce'] = announce
        object['commands'] = Wave::commands(folderProbeMetadata)
        object["default-expression"] = Wave::defaultExpression(folderProbeMetadata, schedule)
        object['schedule'] = schedule
        object["item-data"] = {}
        object["item-data"]["folderpath"] = location
        object["item-data"]["folder-probe-metadata"] = folderProbeMetadata
        object
    end

    def self.generalUpgrade()

        if @@firstRun then
            # Loading all existing disk objects
            Wave::catalystUUIDsEnumerator()
                .each{|uuid|
                    object = Wave::makeCatalystObjectOrNull(uuid)
                    next if object.nil?
                    FlockOperator::addOrUpdateObject(object)
                }
            @@firstRun = false
        end

        # ------------------------------------------------------------------------------
        # First we add to the flock the objects on the repository that are not there yet
        # This happens because some of them are created externally, with the intent that the agent will pick them up

        existingUUIDsFromFlock = FlockOperator::flockObjects()
            .select{|object| object["agent-uid"]==self.agentuuid() }
            .map{|object| object["uuid"] }
        existingUUIDsFromDisk = Wave::catalystUUIDsEnumerator().to_a
        unregisteredUUIDs = existingUUIDsFromDisk - existingUUIDsFromFlock
        unregisteredUUIDs.each{|uuid|
            # We need to build the object, then make a Flock update and emit an event
            object = Wave::makeCatalystObjectOrNull(uuid)
            EventsManager::commitEventToTimeline(EventsMaker::catalystObject(object))
            FlockOperator::addOrUpdateObject(object)
        }

        # ------------------------------------------------------------------------------
        # Removing the emails objects which have been archived by email sync but still in flock

        FlockOperator::flockObjects()
            .clone
            .select{|object| object["agent-uid"]==self.agentuuid() }
            .select{|object| object["schedule"][':wave-emails:'] }
            .select{|object| object["folderpath"] and !File.exists?(object["folderpath"]) }
            .each{|object|
                puts "Wave Agent: email no longer has a folder"
                puts JSON.pretty_generate(object)
                puts "Going to EventsMaker::destroyCatalystObject (You should remove that code when you get tired of it) marker: 45BA5BE9-410C-49B4-A168-0C788189C7FA"
                LucilleCore::pressEnterToContinue()
                uuid = object["uuid"]
                EventsManager::commitEventToTimeline(EventsMaker::destroyCatalystObject(uuid))
            }

        # ------------------------------------------------------------------------------
        # We now need to update the metric driven by the schedule
        # As time passes the metric changes, for instance repeat item pass their sleeping period

        FlockOperator::flockObjects()
            .clone
            .select{|object| object["agent-uid"]==self.agentuuid() }
            .map{|object|
                uuid = object["uuid"]
                schedule = object["schedule"]
                object["metric"] = WaveSchedules::scheduleToMetric(schedule) + CommonsUtils::traceToMetricShift(uuid)
                FlockOperator::addOrUpdateObject(object)
            }
    end

    def self.processObjectAndCommand(object, command)
        uuid = object['uuid']
        schedule = object['schedule']

        doneObjectWithRepeatSchedule = lambda{|object|
            uuid = object['uuid']
            schedule = object['schedule']
            schedule = WaveSchedules::cycleSchedule(schedule)
            object['schedule'] = schedule
            Wave::writeScheduleToDisk(uuid, schedule)
            FlockOperator::addOrUpdateObject(object)
            EventsManager::commitEventToTimeline(EventsMaker::catalystObject(object))
        }

        doneObjectWithOneOffTask = lambda {|object|
            uuid = object['uuid']
            FlockOperator::removeObjectIdentifiedByUUID(uuid)
            EventsManager::commitEventToTimeline(EventsMaker::destroyCatalystObject(uuid))
            Wave::archiveWaveItem(uuid)
        }

        if command=='open' then
            metadata = object["item-data"]["folder-probe-metadata"]
            FolderProbe::openActionOnMetadata(metadata)
        end

        if command=='done' then
            if ["new", 'today', 'ondate'].include?(schedule['@']) then
                doneObjectWithOneOffTask.call(object)
            end
            if ['sticky', 'every-n-hours', 'every-n-days', 'every-this-day-of-the-month', 'every-this-day-of-the-week'].include?(schedule['@']) then
                doneObjectWithRepeatSchedule.call(object)
            end
        end

        if command=='recast' then
            schedule = Wave::makeNewSchedule()
            object['schedule'] = schedule
            Wave::writeScheduleToDisk(uuid, schedule)
            FlockOperator::addOrUpdateObject(object)
            EventsManager::commitEventToTimeline(EventsMaker::catalystObject(object))
        end

        if command == 'description:' then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            uuid = object["uuid"]
            folderpath = Wave::catalystUUIDToItemFolderPathOrNull(uuid)
            File.open("#{folderpath}/description.txt", "w"){|f| f.write(description) }
            object = Wave::makeCatalystObjectOrNull(uuid)
            FlockOperator::addOrUpdateObject(object)
            EventsManager::commitEventToTimeline(EventsMaker::catalystObject(object))
        end

        if command=='folder' then
            location = Wave::catalystUUIDToItemFolderPathOrNull(uuid)
            puts "Opening folder #{location}"
            system("open '#{location}'")
        end

        if command=='destroy' then
            if LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Do you want to destroy this item ? : ") then
                Wave::archiveWaveItem(uuid)
                FlockOperator::removeObjectIdentifiedByUUID(uuid)
                EventsManager::commitEventToTimeline(EventsMaker::destroyCatalystObject(uuid))
            end
        end

        if command=='>stream' then
            sourcelocation = Wave::catalystUUIDToItemFolderPathOrNull(uuid)
            targetfolderpath = "#{CATALYST_COMMON_PATH_TO_STREAM_DATA_FOLDER}/#{LucilleCore::timeStringL22()}"
            FileUtils.mv(sourcelocation, targetfolderpath)
            Wave::removeWaveMetadataFilesAtLocation(targetfolderpath)
            FlockOperator::removeObjectIdentifiedByUUID(uuid)
            EventsManager::commitEventToTimeline(EventsMaker::destroyCatalystObject(uuid))
        end

        if command=='>lib' then
            atlasreference = "atlas-#{SecureRandom.hex(8)}"
            sourcelocation = Wave::catalystUUIDToItemFolderPathOrNull(uuid)
            staginglocation = "/Users/pascal/Desktop/#{atlasreference}"
            LucilleCore::copyFileSystemLocation(sourcelocation, staginglocation)
            Wave::removeWaveMetadataFilesAtLocation(staginglocation)
            puts "Data moved to the staging folder (Desktop), edit and press [Enter]"
            LucilleCore::pressEnterToContinue()
            LibrarianExportedFunctions::librarianUserInterface_makeNewPermanodeInteractive(staginglocation, nil, nil, atlasreference, nil, nil)
            targetlocation = R136CoreUtils::getNewUniqueDataTimelineFolderpath()
            LucilleCore::copyFileSystemLocation(staginglocation, targetlocation)
            LucilleCore::removeFileSystemLocation(staginglocation)
            Wave::archiveWaveItem(uuid)
            FlockOperator::removeObjectIdentifiedByUUID(uuid)
            EventsManager::commitEventToTimeline(EventsMaker::destroyCatalystObject(uuid))
        end
    end
end
