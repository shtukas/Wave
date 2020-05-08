
# encoding: UTF-8

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/CoreData.rb"
=begin

    CoreDataFile::copyFileToRepository(filepath)
    CoreDataFile::filenameToFilepath(filename)
    CoreDataFile::filenameIsCurrent(filename)
    CoreDataFile::openOrCopyToDesktop(filename)
    CoreDataFile::deleteFile(filename)

    CoreDataDirectory::copyFolderToRepository(folderpath)
    CoreDataDirectory::foldernameToFolderpath(foldername)
    CoreDataDirectory::openFolder(foldername)
    CoreDataDirectory::deleteFolder(foldername)

=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

require_relative "../Catalyst-Common/Catalyst-Common.rb"

# -----------------------------------------------------------------

class Projects

    # -----------------------------------------------------------
    # Projects

    # Projects::pathToProjects()
    def self.pathToProjects()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Projects/projects1"
    end

    # Projects::projects()
    def self.projects()
        Dir.entries(Projects::pathToProjects())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{Projects::pathToProjects()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|c1, c2| c1["creationtime"] <=> c2["creationtime"] }
    end

    # Projects::getProjectByUUIDOrNUll(uuid)
    def self.getProjectByUUIDOrNUll(uuid)
        filepath = "#{Projects::pathToProjects()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # Projects::save(project)
    def self.save(project)
        uuid = project["uuid"]
        File.open("#{Projects::pathToProjects()}/#{uuid}.json", "w"){|f| f.puts(JSON.pretty_generate(project)) }
    end

    # Projects::destroy(project)
    def self.destroy(project)
        uuid = project["uuid"]
        filepath = "#{Projects::pathToProjects()}/#{uuid}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # Projects::makeProject(uuid, description, schedule, items)
    def self.makeProject(uuid, description, schedule, items)
        {
            "uuid"         => uuid,
            "creationtime" => Time.new.to_f,
            "description"  => description,
            "schedule" => schedule,
            "items"        => items
        }
    end

    # Projects::issueProject(uuid, description, schedule, items)
    def self.issueProject(uuid, description, schedule, items)
        project = Projects::makeProject(uuid, description, schedule, items)
        Projects::save(project)
    end

    # Projects::selectProjectOrNull()
    def self.selectProjectOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("project:", Projects::projects(), lambda {|project| project["description"] })
    end

    # -----------------------------------------------------------
    # Items Management

    # Projects::insertProjectItem(projectuuid, item)
    def self.insertProjectItem(projectuuid, item)
        BTreeSets::set("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/items1", projectuuid, item["uuid"], item)
    end

    # Projects::getProjectItemByItemUuidOrNull(projectuuid, itemuuid)
    def self.getProjectItemByItemUuidOrNull(projectuuid, itemuuid)
        BTreeSets::getOrNull("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/items1", projectuuid, itemuuid)
    end

    # Projects::getProjectItemsByCreationTime(projectuuid)
    def self.getProjectItemsByCreationTime(projectuuid)
        BTreeSets::values("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/items1", projectuuid)
            .sort{|i1, i2| i1["creationtime"]<=>i2["creationtime"] }
    end

    # -----------------------------------------------------------
    # Run Management

    # Projects::isRunning(uuid)
    def self.isRunning(uuid)
        !KeyValueStore::getOrNull(nil, "db183530-293a-41f8-b260-283c59659bd5:#{uuid}").nil?
    end

    # Projects::runTimeInSecondsOrNull(uuid)
    def self.runTimeInSecondsOrNull(uuid)
        unixtime = KeyValueStore::getOrNull(nil, "db183530-293a-41f8-b260-283c59659bd5:#{uuid}")
        return nil if unixtime.nil?
        Time.new.to_f - unixtime.to_f
    end

    # Projects::start(uuid)
    def self.start(uuid)
        return if Projects::isRunning(uuid)
        KeyValueStore::set(nil, "db183530-293a-41f8-b260-283c59659bd5:#{uuid}", Time.new.to_i)
    end

    # Projects::insertAlgebraicTime(uuid, algebraicTimespanInSeconds)
    def self.insertAlgebraicTime(uuid, algebraicTimespanInSeconds)
        timepoint = {
            "uuid"     => SecureRandom.uuid,
            "unixtime" => Time.new.to_i,
            "timespan" => algebraicTimespanInSeconds
        }
        BTreeSets::set(nil, "acc68599-2249-42fc-b6dd-f7db287c73db:#{uuid}", timepoint["uuid"], timepoint)
    end

    # Projects::stop(uuid)
    def self.stop(uuid)
        return if !Projects::isRunning(uuid)
        unixtime = KeyValueStore::getOrNull(nil, "db183530-293a-41f8-b260-283c59659bd5:#{uuid}").to_i
        unixtime = unixtime.to_f
        timespan = Time.new.to_f - unixtime
        timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
        Projects::insertAlgebraicTime(uuid, timespan)
        KeyValueStore::destroy(nil, "db183530-293a-41f8-b260-283c59659bd5:#{uuid}")
    end

    # Projects::getTimepoints(uuid)
    def self.getTimepoints(uuid)
        BTreeSets::values(nil, "acc68599-2249-42fc-b6dd-f7db287c73db:#{uuid}")
    end

    # Projects::getStoredRunTimespan(uuid)
    def self.getStoredRunTimespan(uuid)
        Projects::getTimepoints(uuid)
            .map{|point| point["timespan"] }
            .inject(0, :+)
    end

    # Projects::getStoredRunTimespanOverThePastNSeconds(uuid, n)
    def self.getStoredRunTimespanOverThePastNSeconds(uuid, n)
        Projects::getTimepoints(uuid)
            .select{|timepoint| (Time.new.to_f - timepoint["unixtime"]) <= n }
            .map{|point| point["timespan"] }
            .inject(0, :+)
    end

    # -----------------------------------------------------------
    # In Flight Control System

    # Projects::getIFCSProjects()
    def self.getIFCSProjects()
        Projects::projects()
            .select{|project| project["schedule"]["type"] == "ifcs" }
            .sort{|p1, p2| p1["schedule"]["position"] <=> p2["schedule"]["position"] }
    end

    # Projects::getOrderedIfcsProjectsWithComputedOrdinal()
    def self.getOrderedIfcsProjectsWithComputedOrdinal() # Array[ (project, ordinal: Int) ]
        Projects::getIFCSProjects()
            .map
            .with_index
            .to_a
    end

    # Projects::getOrdinal(uuid)
    def self.getOrdinal(uuid)
        Projects::getOrderedIfcsProjectsWithComputedOrdinal()
            .select{|pair| pair[0]["uuid"] == uuid }
            .map{|pair| pair[1] }
            .first
    end

    # Projects::stopOrStart()
    def self.stopOrStart()
        if Projects::getIFCSProjects().any?{|project| Projects::isRunning(project["uuid"]) } then
            Projects::getIFCSProjects()
                .each{|project| Projects::stop(project["uuid"]) }
        else
            Projects::getIFCSProjects()
                .sort{|project1, project2| Projects::getStoredRunTimespan(project1["uuid"]) <=> Projects::getStoredRunTimespan(project2["uuid"]) }
                .first(1)
                .each{|project| Projects::start(project["uuid"]) }
        end
    end

    # Presents the current priority list of the caller and let them enter a number that is then returned
    # Projects::interactiveChoiceOfPosition()
    def self.interactiveChoiceOfPosition() # Float
        puts "Items"
        Projects::getIFCSProjects()
            .each{|project|
                uuid = project["uuid"]
                puts "    - #{("%5.3f" % project["schedule"]["position"])} #{project["description"]}"
            }
        LucilleCore::askQuestionAnswerAsString("position: ").to_f
    end

    # Projects::uuidTotalTimespanIncludingLiveRun(uuid)
    def self.uuidTotalTimespanIncludingLiveRun(uuid)
        x0 = Projects::getStoredRunTimespan(uuid)
        x1 = 0
        unixtime = KeyValueStore::getOrNull(nil, "db183530-293a-41f8-b260-283c59659bd5:#{uuid}")
        if unixtime then
            x1 = Time.new.to_f - unixtime.to_f
        end
        x0 + x1
    end

    # Projects::timeToMetric(uuid, timeInSeconds, interfaceDiveIsRunning)
    def self.timeToMetric(uuid, timeInSeconds, interfaceDiveIsRunning)
        return 1 if Projects::isRunning(uuid)
        return 0 if interfaceDiveIsRunning # We kill other items when Interface Dive is running
        timeInHours = timeInSeconds.to_f/3600
        return 0.76 + Math.atan(-timeInHours).to_f/1000 if timeInHours > 0
        0.76 + Math.atan(-timeInHours).to_f/1000
    end

    # Projects::metric(uuid)
    def self.metric(uuid)
        Projects::timeToMetric(uuid, Projects::getStoredRunTimespan(uuid), Projects::isRunning("20200502-141716-483780"))
    end

    # Projects::isWeekDay()
    def self.isWeekDay()
        [1,2,3,4,5].include?(Time.new.wday)
    end

    # Projects::operatingTimespanMapping()
    def self.operatingTimespanMapping()
        if Projects::isWeekDay() then
            {
                "GuardianGeneralWork" => 5 * 3600,
                "InterfaceDive"       => 2 * 3600,
                "IFCSStandard"        => 2 * 3600
            }
        else
            {
                "GuardianGeneralWork" => 0 * 3600,
                "InterfaceDive"       => 4 * 3600,
                "IFCSStandard"        => 4 * 3600
            }
        end
    end

    # Projects::ordinalTo24HoursTimeExpectationInSeconds(ordinal)
    def self.ordinalTo24HoursTimeExpectationInSeconds(ordinal)
        Projects::operatingTimespanMapping()["IFCSStandard"] * (1.to_f / 2**(ordinal+1))
    end

    # Projects::itemPractical24HoursTimeExpectationInSecondsOrNull(uuid)
    def self.itemPractical24HoursTimeExpectationInSecondsOrNull(uuid)
        return nil if Projects::getStoredRunTimespan(uuid) < -3600 # This allows small targets to get some time and the big ones not to become overwelming
        if uuid == "20200502-141331-226084" then # Guardian General Work
            return Projects::operatingTimespanMapping()["GuardianGeneralWork"]
        end
        if uuid == "20200502-141716-483780" then 
            return Projects::operatingTimespanMapping()["InterfaceDive"]
        end
        Projects::ordinalTo24HoursTimeExpectationInSeconds(Projects::getOrdinal(uuid))
    end

    # Projects::distributeDayTimeCommitmentsIfNotDoneAlready()
    def self.distributeDayTimeCommitmentsIfNotDoneAlready()
        return if Time.new.hour < 9
        return if Time.new.hour > 18
        Projects::getIFCSProjects()
            .each{|project|
                uuid = project["uuid"]
                next if KeyValueStore::flagIsTrue(nil, "2f6255ce-e877-4122-817b-b657c2b0eb29:#{uuid}:#{Time.new.to_s[0, 10]}")
                timespan = Projects::itemPractical24HoursTimeExpectationInSecondsOrNull(uuid)
                next if timespan.nil?
                Projects::insertAlgebraicTime(uuid, -timespan)
                KeyValueStore::setFlagTrue(nil, "2f6255ce-e877-4122-817b-b657c2b0eb29:#{uuid}:#{Time.new.to_s[0, 10]}")
            }
    end

    # -----------------------------------------------------------
    # User Interface

    # Projects::projectKickerText(project)
    def self.projectKickerText(project)
        uuid = project["uuid"]
        if project["schedule"]["type"] == "standard" then
            return "[project standard ; st: #{"%7.2f" % (Projects::getStoredRunTimespan(uuid).to_f/3600)} hours]"
        end
        if project["schedule"]["type"] == "ifcs" then
            return "[project ifcs ; pos: #{("%6.3f" % project["schedule"]["position"])} ; ord: #{"%2d" % Projects::getOrdinal(uuid)} ; st: #{"%5.2f" % (Projects::getStoredRunTimespan(uuid).to_f/3600)}]"
        end
        raise "Projects: f40a0f00"
    end

    # Projects::projectSuffixText(project)
    def self.projectSuffixText(project)
        uuid = project["uuid"]
        str1 = " (#{Projects::getProjectItemsByCreationTime(project["uuid"]).size})"
        puts Projects::getProjectItemsByCreationTime(project["uuid"])
        str2 = 
            if Projects::isRunning(uuid) then
                " (running for #{(Projects::runTimeInSecondsOrNull(uuid).to_f/3600).round(2)} hours)"
            else
                ""
            end
        if project["schedule"]["type"] == "standard" then
            return "#{str1}#{str2}"
        end
        if project["schedule"]["type"] == "ifcs" then
            return "#{str1}#{str2}"
        end
        raise "Projects: 85cdae2a"
    end

    # Projects::projectToString(project)
    def self.projectToString(project)
        "#{Projects::projectKickerText(project)} #{project["description"]}#{Projects::projectSuffixText(project)}"
    end

    # Projects::diveProject(project)
    def self.diveProject(project)
        options = [
            "start"
        ]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
        return if option.nil?
        if option == "start" then
            Projects::start(project["uuid"])
        end
    end

end


