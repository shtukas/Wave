#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require "/Galaxy/local-resources/Ruby-Libraries/FIFOQueue.rb"

# ----------------------------------------------------------------

CATALYST_COMMON_DATA_FOLDERPATH = "/Galaxy/DataBank/Catalyst"
CATALYST_COMMON_CONFIG_FILEPATH = "#{CATALYST_COMMON_DATA_FOLDERPATH}/Config.json"
CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH = "#{CATALYST_COMMON_DATA_FOLDERPATH}/Archives-Timeline"
CATALYST_COMMON_XCACHE_REPOSITORY = "#{CATALYST_COMMON_DATA_FOLDERPATH}/xcache"
CATALYST_COMMON_PATH_TO_STREAM_DATA_FOLDER = "#{CATALYST_COMMON_DATA_FOLDERPATH}/Agents-Data/Stream"
CATALYST_COMMON_PATH_TO_OPEN_PROJECTS_DATA_FOLDER = "#{CATALYST_COMMON_DATA_FOLDERPATH}/Agents-Data/Open-Projects"


# ----------------------------------------------------------------

# Config::get(keyname)

class Config
    def self.getConfig()
        JSON.parse(IO.read(CATALYST_COMMON_CONFIG_FILEPATH))
    end
    def self.get(keyname)
        self.getConfig()[keyname]
    end
end

# Saturn::isPrimaryComputer()
# Saturn::currentHour()
# Saturn::currentDay()
# Saturn::simplifyURLCarryingString(string)
# Saturn::traceToRealInUnitInterval(trace)
# Saturn::traceToMetricShift(trace)
# Saturn::deathObject(uuid)
# Saturn::realNumbersToZeroOne(x, origin, unit)

class Saturn

    def self.isPrimaryComputer()
        ENV["COMPUTERLUCILLENAME"]==Config::get("PrimaryComputerName")
    end

    def self.currentHour()
        Time.new.to_s[0,13]
    end

    def self.currentDay()
        Time.new.to_s[0,10]
    end

    def self.simplifyURLCarryingString(string)
        return string if /http/.match(string).nil?
        [/^\{\s\d*\s\}/, /^\[\]/, /^line:/, /^todo:/, /^url:/, /^\[\s*\d*\s*\]/]
            .each{|regex|
                if ( m = regex.match(string) ) then
                    string = string[m.to_s.size, string.size].strip
                    return Saturn::simplifyURLCarryingString(string)
                end
            }
        string
    end

    def self.traceToRealInUnitInterval(trace)
        ( '0.'+Digest::SHA1.hexdigest(trace).gsub(/[^\d]/, '') ).to_f
    end

    def self.traceToMetricShift(trace)
        0.001*Saturn::traceToRealInUnitInterval(trace)
    end

    def self.deathObject(uuid)
        {
            "uuid"  => uuid,
            "death" => true
        }
    end

    def self.realNumbersToZeroOne(x, origin, unit)
        alpha =
            if x >= origin then
                2-Math.exp(-(x-origin).to_f/unit)
            else
                Math.exp((x-origin).to_f/unit)
            end
        alpha.to_f/2
    end
end

# DoNotShowUntil::set(uuid, datetime)
# DoNotShowUntil::getDatetime(uuid)
# DoNotShowUntil::transform(objects)

class DoNotShowUntil
    def self.set(uuid, datetime)
        KeyValueStore::set(CATALYST_COMMON_XCACHE_REPOSITORY, "7abd0c37-ef4f-4214-843b-c5c0f09b8e72:#{uuid}", datetime)
    end

    def self.getDatetime(uuid)
        KeyValueStore::getOrDefaultValue(CATALYST_COMMON_XCACHE_REPOSITORY, "7abd0c37-ef4f-4214-843b-c5c0f09b8e72:#{uuid}", "2018-01-01 00:00:00 +0000")
    end

    def self.isactive(object)
        Time.new.to_i >= DateTime.parse(DoNotShowUntil::getDatetime(object["uuid"])).to_time.to_i
    end

    def self.transform(objects)
        objects.map{|object|
            if !DoNotShowUntil::isactive(object) then
                object["metric-before-do-not-show"] = object["metric"]
                object["do-not-show-until-datetime"] = DoNotShowUntil::getDatetime(object["uuid"])
                # next we try to promote any do-not-show-until-datetime contained in a scheduler of a wave item, with a target in the future
                if object["do-not-show-until-datetime"].nil? and object["schedule"] and object["schedule"]["do-not-show-until-datetime"] and (Time.new.to_s < object["schedule"]["do-not-show-until-datetime"]) then
                    object["do-not-show-until-datetime"] = object["schedule"]["do-not-show-until-datetime"]
                end
                object["metric"] = 0
            end
            object
        }
    end
end

# RequirementsOperator::getCurrentlyUnsatisfiedRequirements()
# RequirementsOperator::setUnsatisfiedRequirement(requirement)
# RequirementsOperator::setSatisfifiedRequirement(requirement)
# RequirementsOperator::requirementIsCurrentlySatisfied(requirement)

# RequirementsOperator::getObjectRequirements(uuid)
# RequirementsOperator::setObjectRequirements(uuid, requirements)
# RequirementsOperator::addRequirementToObject(uuid,requirement)
# RequirementsOperator::removeRequirementFromObject(uuid,requirement)
# RequirementsOperator::objectMeetsRequirements(uuid)

# RequirementsOperator::getAllRequirements()

class RequirementsOperator

    def self.getCurrentlyUnsatisfiedRequirements()
        JSON.parse(KeyValueStore::getOrDefaultValue(CATALYST_COMMON_XCACHE_REPOSITORY, "Currently-Unsatisfied-Requirements-7f8bba56-6755-401c-a1d2-490c0176337e", "[]"))
    end

    def self.setUnsatisfiedRequirement(requirement)
        rs = RequirementsOperator::getCurrentlyUnsatisfiedRequirements()
        rs = (rs + [ requirement ]).uniq
        KeyValueStore::set(CATALYST_COMMON_XCACHE_REPOSITORY, "Currently-Unsatisfied-Requirements-7f8bba56-6755-401c-a1d2-490c0176337e", JSON.generate(rs))
    end

    def self.setSatisfifiedRequirement(requirement)
        rs = RequirementsOperator::getCurrentlyUnsatisfiedRequirements()
        rs = rs.reject{|r| r==requirement }
        KeyValueStore::set(CATALYST_COMMON_XCACHE_REPOSITORY, "Currently-Unsatisfied-Requirements-7f8bba56-6755-401c-a1d2-490c0176337e", JSON.generate(rs))
    end

    def self.requirementIsCurrentlySatisfied(requirement)
        !RequirementsOperator::getCurrentlyUnsatisfiedRequirements().include?(requirement)
    end

    # objects

    def self.getObjectRequirements(uuid)
        JSON.parse(KeyValueStore::getOrDefaultValue(CATALYST_COMMON_XCACHE_REPOSITORY, "Object-Requirements-List-6acb38bd-3c4a-4265-a920-2c89154125ce:#{uuid}", "[]"))
    end

    def self.setObjectRequirements(uuid, requirements)
        KeyValueStore::set(CATALYST_COMMON_XCACHE_REPOSITORY, "Object-Requirements-List-6acb38bd-3c4a-4265-a920-2c89154125ce:#{uuid}", JSON.generate(requirements))
    end

    def self.addRequirementToObject(uuid,requirement)
        RequirementsOperator::setObjectRequirements(uuid, (RequirementsOperator::getObjectRequirements(uuid) + [requirement]).uniq)
    end

    def self.removeRequirementFromObject(uuid,requirement)
        RequirementsOperator::setObjectRequirements(uuid, (RequirementsOperator::getObjectRequirements(uuid).reject{|r| r==requirement }))
    end

    def self.objectMeetsRequirements(uuid)
        RequirementsOperator::getObjectRequirements(uuid)
            .all?{|requirement| RequirementsOperator::requirementIsCurrentlySatisfied(requirement) }
    end

    def self.getAllRequirements()
        JSON.parse(KeyValueStore::getOrDefaultValue(CATALYST_COMMON_XCACHE_REPOSITORY, "Externally-Set-All-Requirements-23922D81-25EB-4C19-845D-22D9475E2196", "[]"))
    end

    def self.selectRequirementFromExistingRequirementsOrNull()
        LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("requirement", RequirementsOperator::getAllRequirements())
    end
end

# TodayOrNotToday::notToday(uuid)
# TodayOrNotToday::todayOk(uuid)

class TodayOrNotToday
    def self.notToday(uuid)
        KeyValueStore::set(CATALYST_COMMON_XCACHE_REPOSITORY, "9e8881b5-3bf7-4a08-b454-6b8b827cd0e0:#{Saturn::currentDay()}:#{uuid}", "!today")
    end
    def self.todayOk(uuid)
        KeyValueStore::getOrNull(CATALYST_COMMON_XCACHE_REPOSITORY, "9e8881b5-3bf7-4a08-b454-6b8b827cd0e0:#{Saturn::currentDay()}:#{uuid}").nil?
    end
end

# FolderProbe::nonDotFilespathsAtFolder(folderpath)
# FolderProbe::folderpath2metadata(folderpath)
    #    {
    #        "target-type" => "folder"
    #        "target-location" =>
    #        "announce" =>
    #    }
    #    {
    #        "target-type" => "openable-file"
    #        "target-location" =>
    #        "announce" =>
    #    }
    #    {
    #        "target-type" => "line",
    #        "text" => line
    #        "announce" =>
    #    }
    #    {
    #        "target-type" => "url",
    #        "url" =>
    #        "announce" =>
    #    }
    #    {
    #        "target-type" => "virtually-empty-wave-folder",
    #        "announce" =>
    #    }

# FolderProbe::openActionOnMetadata(metadata)

class FolderProbe
    def self.nonDotFilespathsAtFolder(folderpath)
        Dir.entries(folderpath)
            .select{|filename| filename[0,1]!="." }
            .map{|filename| "#{folderpath}/#{filename}" }
    end

    def self.folderpath2metadata(folderpath)

        metadata = {}

        # --------------------------------------------------------------------
        # Trying to read a description file

        getDescriptionFilepathMaybe = lambda{|folderpath|
            filepaths = FolderProbe::nonDotFilespathsAtFolder(folderpath)
            if filepaths.any?{|filepath| File.basename(filepath).include?("description.txt") } then
                filepaths.select{|filepath| File.basename(filepath).include?("description.txt") }.first
            else
                nil
            end
        }

        getDescriptionFromDescriptionFileMaybe = lambda{|folderpath|
            filepathOpt = getDescriptionFilepathMaybe.call(folderpath)
            if filepathOpt then
                IO.read(filepathOpt).strip
            else
                nil
            end
        }

        descriptionOpt = getDescriptionFromDescriptionFileMaybe.call(folderpath)
        if descriptionOpt then
            metadata["announce"] = descriptionOpt
            if descriptionOpt.start_with?("http") then
                metadata["target-type"] = "url"
                metadata["url"] = descriptionOpt
                return metadata
            end
        end

        # --------------------------------------------------------------------
        #

        files = FolderProbe::nonDotFilespathsAtFolder(folderpath)
                .select{|filepath| !File.basename(filepath).start_with?('wave') }
                .select{|filepath| !File.basename(filepath).start_with?('catalyst') }

        fileIsOpenable = lambda {|filepath|
            File.basename(filepath)[-4,4]==".txt" or
            File.basename(filepath)[-4,4]==".eml" or
            File.basename(filepath)[-4,4]==".jpg" or
            File.basename(filepath)[-4,4]==".png" or
            File.basename(filepath)[-4,4]==".gif" or
            File.basename(filepath)[-7,7]==".webloc"
        }

        openableFiles = files
                .select{|filepath| fileIsOpenable.call(filepath) }


        filesWithoutTheDescription = files
                .select{|filepath| !File.basename(filepath).include?('description.txt') }

        extractURLFromFileMaybe = lambda{|filepath|
            return nil if filepath[-4,4] != ".txt"
            contents = IO.read(filepath)
            return nil if contents.lines.to_a.size != 1
            line = contents.lines.first.strip
            line = Saturn::simplifyURLCarryingString(line)
            return nil if !line.start_with?("http")
            line
        }

        extractLineFromFileMaybe = lambda{|filepath|
            return nil if filepath[-4,4] != ".txt"
            contents = IO.read(filepath)
            return nil if contents.lines.to_a.size != 1
            contents.lines.first.strip
        }

        if files.size==0 then
            # There is one open able file in the folder
            metadata["target-type"] = "virtually-empty-wave-folder"
            if metadata["announce"].nil? then
                metadata["announce"] = folderpath
            end
            return metadata
        end

        if files.size==1 and ( url = extractURLFromFileMaybe.call(files[0]) ) then
            filepath = files.first
            metadata["target-type"] = "url"
            metadata["url"] = url
            if metadata["announce"].nil? then
                metadata["announce"] = url
            end
            return metadata
        end

        if files.size==1 and ( line = extractLineFromFileMaybe.call(files[0]) ) then
            filepath = files.first
            metadata["target-type"] = "line"
            metadata["text"] = line
            if metadata["announce"].nil? then
                metadata["announce"] = line
            end
            return metadata
        end

        if files.size==1 and openableFiles.size==1 then
            filepath = files.first
            metadata["target-type"] = "openable-file"
            metadata["target-location"] = filepath
            if metadata["announce"].nil? then
                metadata["announce"] = File.basename(filepath)
            end
            return metadata
        end

        if files.size==1 and openableFiles.size!=1 then
            filepath = files.first
            metadata["target-type"] = "folder"
            metadata["target-location"] = folderpath
            if metadata["announce"].nil? then
                metadata["announce"] = "One non-openable file in #{File.basename(folderpath)}"
            end
            return metadata
        end

        if files.size > 1 and filesWithoutTheDescription.size==1 and fileIsOpenable.call(filesWithoutTheDescription.first) then
            metadata["target-type"] = "openable-file"
            metadata["target-location"] = filesWithoutTheDescription.first
            if metadata["announce"].nil? then
                metadata["announce"] = "Multiple files in #{File.basename(folderpath)}"
            end
            return metadata
        end

        if files.size > 1 then
            metadata["target-type"] = "folder"
            metadata["target-location"] = folderpath
            if metadata["announce"].nil? then
                metadata["announce"] = "Multiple files in #{File.basename(folderpath)}"
            end
            return metadata
        end
    end

    def self.openActionOnMetadata(metadata)
        if metadata["target-type"]=="folder" then
            system("open '#{metadata["target-location"]}'")
        end
        if metadata["target-type"]=="openable-file" then
            system("open '#{metadata["target-location"]}'")
        end
        if metadata["target-type"]=="line" then
            puts metadata["text"]
        end
        if metadata["target-type"]=="url" then
            system("open '#{metadata["url"]}'")
        end
        if metadata["target-type"]=="virtually-empty-wave-folder" then
            puts metadata["announce"]
        end
    end
end

# GenericTimeTracking::status(uuid): [boolean, null or unixtime]
# GenericTimeTracking::start(uuid)
# GenericTimeTracking::stop(uuid)
# GenericTimeTracking::metric2(uuid, low, high, hourstoMinusOne)
# GenericTimeTracking::timings(uuid)

class GenericTimeTracking
    def self.status(uuid)
        JSON.parse(KeyValueStore::getOrDefaultValue(CATALYST_COMMON_XCACHE_REPOSITORY, "status:d0742c76-b83a-4fa4-9264-cfb5b21f8dc4:#{uuid}", "[false, null]"))
    end

    def self.start(uuid)
        status = GenericTimeTracking::status(uuid)
        return if status[0]
        status = [true, Time.new.to_i]
        KeyValueStore::set(CATALYST_COMMON_XCACHE_REPOSITORY, "status:d0742c76-b83a-4fa4-9264-cfb5b21f8dc4:#{uuid}", JSON.generate(status))
    end

    def self.stop(uuid)
        status = GenericTimeTracking::status(uuid)
        return if !status[0]
        timespan = Time.new.to_i - status[1]
        FIFOQueue::push(CATALYST_COMMON_XCACHE_REPOSITORY, "timespans:f13bdb69-9313-4097-930c-63af0696b92d:#{uuid}", [Time.new.to_i, timespan])
        status = [false, nil]
        KeyValueStore::set(CATALYST_COMMON_XCACHE_REPOSITORY, "status:d0742c76-b83a-4fa4-9264-cfb5b21f8dc4:#{uuid}", JSON.generate(status))
    end

    def self.metric2(uuid, low, high, hourstoMinusOne)
        adaptedTimespanInSeconds = FIFOQueue::values(CATALYST_COMMON_XCACHE_REPOSITORY, "timespans:f13bdb69-9313-4097-930c-63af0696b92d:#{uuid}")
            .map{|pair|
                unixtime = pair[0]
                timespan = pair[1]
                ageInSeconds = Time.new.to_i - unixtime
                ageInDays = ageInSeconds.to_f/86400
                timespan * Math.exp(-ageInDays)
            }
            .inject(0, :+)
        adaptedTimespanInHours = adaptedTimespanInSeconds.to_f/3600
        low + (high-low)*Math.exp(-adaptedTimespanInHours.to_f/hourstoMinusOne)
    end

    def self.timings(uuid)
        FIFOQueue::values(CATALYST_COMMON_XCACHE_REPOSITORY, "timespans:f13bdb69-9313-4097-930c-63af0696b92d:#{uuid}")
    end
end

# CatalystDevOps::today()
# CatalystDevOps::getArchiveSizeInMegaBytes()
# CatalystDevOps::getFirstDiveFirstLocationAtLocation(location)
# CatalystDevOps::archivesGarbageCollection(verbose): Int # number of items removed
# CatalystDevOps::xcacheGarbageCollection()

class CatalystDevOps

    def self.today()
        DateTime.now.to_date.to_s
    end

    def self.getFirstDiveFirstLocationAtLocation(location)
        if File.file?(location) then
            location
        else
            locations = Dir.entries(location)
                .select{|filename| filename!='.' and filename!='..' }
                .sort
                .map{|filename| "#{location}/#{filename}" }
            if locations.size==0 then
                location
            else
                locationsdirectories = locations.select{|location| File.directory?(location) }
                if locationsdirectories.size>0 then
                    CatalystDevOps::getFirstDiveFirstLocationAtLocation(locationsdirectories.first)
                else
                    locations.first
                end
            end
        end
    end

    def self.getFilepathAgeInDays(filepath)
        (Time.new.to_i - File.mtime(filepath).to_i).to_f/86400
    end

    # -------------------------------------------
    # Archives

    def self.getArchiveSizeInMegaBytes()
        LucilleCore::locationRecursiveSize(CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH).to_f/(1024*1024)
    end

    def self.archivesGarbageCollectionStandard(verbose)
        answer = 0
        while CatalystDevOps::getArchiveSizeInMegaBytes() > 1024 do # Gigabytes of Archives
            location = CatalystDevOps::getFirstDiveFirstLocationAtLocation(CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH)
            break if location == CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH
            puts "Garbage Collection: Removing: #{location}" if verbose
            LucilleCore::removeFileSystemLocation(location)
            answer = answer + 1
        end
        answer
    end

    def self.archivesGarbageCollectionFast(verbose, sizeEstimationInMegaBytes)
        answer = 0
        while sizeEstimationInMegaBytes > 1024 do # Gigabytes of Archives
            location = CatalystDevOps::getFirstDiveFirstLocationAtLocation(CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH)
            break if location == CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH
            if File.file?(location) then
                sizeEstimationInMegaBytes = sizeEstimationInMegaBytes - File.size(location).to_f/(1024*1024)
            end
            puts "Garbage Collection: Removing: #{location}" if verbose
            LucilleCore::removeFileSystemLocation(location)
            answer = answer + 1
        end
        answer
    end

    def self.archivesGarbageCollection(verbose)
        answer = 0
        while CatalystDevOps::getArchiveSizeInMegaBytes() > 1024 do # Gigabytes of Archives
            location = CatalystDevOps::getFirstDiveFirstLocationAtLocation(CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH)
            break if location == CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH
            answer = answer + CatalystDevOps::archivesGarbageCollectionFast(verbose, CatalystDevOps::getArchiveSizeInMegaBytes())
        end
        answer
    end

    # -------------------------------------------
    # xcache

    def self.xcacheDataFilepathEnumerator(subfolder)
        Enumerator.new do |filepaths|
            Find.find("#{CATALYST_COMMON_XCACHE_REPOSITORY}/#{subfolder}") do |path|
                if path[-5, 5] == '.data' then
                    filepaths << path
                end
            end
        end
    end

    def self.xcacheFolderpathEnumerator(subfolder)
        Enumerator.new do |paths|
            Find.find("#{CATALYST_COMMON_XCACHE_REPOSITORY}/#{subfolder}") do |path|
                next if !File.directory?(path)
                paths << path
            end
        end
    end

    def self.xcacheGarbageCollection(subfolder = "")
        CatalystDevOps::xcacheDataFilepathEnumerator(subfolder).each{|filepath|
            if CatalystDevOps::getFilepathAgeInDays(filepath) > 60 then
                puts "removing: #{filepath}"
                FileUtils.rm(filepath)
            end
        }
        CatalystDevOps::xcacheFolderpathEnumerator(subfolder).each{|path|
            next if Dir.entries(path).select{|filepath| filepath[0,1]!="." }.size>0
            LucilleCore::removeFileSystemLocation(path)
        }
    end

end
