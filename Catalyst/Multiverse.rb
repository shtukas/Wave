# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Multiverse.rb"

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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DataEntities.rb"

# -----------------------------------------------------------------

class Timelines

    # Timelines::path()
    def self.path()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Multiverse/timelines"
    end

    # Timelines::save(node)
    def self.save(node)
        filepath = "#{Timelines::path()}/#{node["uuid"]}.json"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(node)) }
    end

    # Timelines::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{Timelines::path()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # Timelines::timelines()
    # Nodes are given in increasing creation timestamp
    def self.timelines()
        Dir.entries(Timelines::path())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{Timelines::path()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|i1, i2| i1["creationTimestamp"]<=>i2["creationTimestamp"] }
    end

    # Timelines::makeTimelineInteractivelyOrNull(canAskToMakeAParent)
    def self.makeTimelineInteractivelyOrNull(canAskToMakeAParent)
        puts "Making a new Starlight node..."
        node = {
            "catalystType"      => "catalyst-type:timeline",
            "creationTimestamp" => Time.new.to_f,
            "uuid"              => SecureRandom.uuid,

            "name" => LucilleCore::askQuestionAnswerAsString("nodename: ")
        }
        Timelines::save(node)
        puts JSON.pretty_generate(node)
        if canAskToMakeAParent and LucilleCore::askQuestionAnswerAsBoolean("Would you like to give a parent to this new node ? ") then
            xnode = Multiverse::selectOrNull()
            if xnode then
                Stargates::issuePathFromFirstNodeToSecondNodeOrNull(xnode, node)
            end
        end
        node
    end

    # Timelines::timelineToString(node)
    def self.timelineToString(node)
        "[timeline] #{node["name"]} (#{node["uuid"][0, 4]})"
    end
end

class Stargates

    # Stargates::path()
    def self.path()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Multiverse/paths"
    end

    # Stargates::save(path)
    def self.save(path)
        filepath = "#{Stargates::path()}/#{path["uuid"]}.json"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(path)) }
    end

    # Stargates::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{Stargates::path()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # Stargates::paths()
    def self.paths()
        Dir.entries(Stargates::path())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{Stargates::path()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|i1, i2| i1["creationTimestamp"]<=>i2["creationTimestamp"] }
    end

    # Stargates::issuePathInteractivelyOrNull()
    def self.issuePathInteractivelyOrNull()
        path = {
            "catalystType"      => "catalyst-type:starlight-path",
            "creationTimestamp" => Time.new.to_f,
            "uuid"              => SecureRandom.uuid,

            "sourceuuid" => LucilleCore::askQuestionAnswerAsString("sourceuuid: "),
            "targetuuid" => LucilleCore::askQuestionAnswerAsString("targetuuid: ")
        }
        Stargates::save(path)
        path
    end

    # Stargates::issuePathFromFirstNodeToSecondNodeOrNull(node1, node2)
    def self.issuePathFromFirstNodeToSecondNodeOrNull(node1, node2)
        return nil if node1["uuid"] == node2["uuid"]
        path = {
            "catalystType"      => "catalyst-type:starlight-path",
            "creationTimestamp" => Time.new.to_f,
            "uuid"              => SecureRandom.uuid,
            "sourceuuid" => node1["uuid"],
            "targetuuid" => node2["uuid"]
        }
        Stargates::save(path)
        path
    end

    # Stargates::getPathsWithGivenTarget(targetuuid)
    def self.getPathsWithGivenTarget(targetuuid)
        Stargates::paths()
            .select{|path| path["targetuuid"] == targetuuid }
    end

    # Stargates::getPathsWithGivenSource(sourceuuid)
    def self.getPathsWithGivenSource(sourceuuid)
        Stargates::paths()
            .select{|path| path["sourceuuid"] == sourceuuid }
    end

    # Stargates::pathToString(path)
    def self.pathToString(path)
        "[stargate] #{path["sourceuuid"]} -> #{path["targetuuid"]}"
    end

    # Stargates::getParentNodes(node)
    def self.getParentNodes(node)
        Stargates::getPathsWithGivenTarget(node["uuid"])
            .map{|path| Timelines::getOrNull(path["sourceuuid"]) }
            .compact
    end

    # Stargates::getChildNodes(node)
    def self.getChildNodes(node)
        Stargates::getPathsWithGivenSource(node["uuid"])
            .map{|path| Timelines::getOrNull(path["targetuuid"]) }
            .compact
    end
end

class TimelineOwnership

    # TimelineOwnership::path()
    def self.path()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Multiverse/ownershipclaims"
    end

    # TimelineOwnership::save(dataclaim)
    def self.save(dataclaim)
        filepath = "#{TimelineOwnership::path()}/#{dataclaim["uuid"]}.json"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(dataclaim)) }
    end

    # TimelineOwnership::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{TimelineOwnership::path()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # TimelineOwnership::claims()
    def self.claims()
        Dir.entries(TimelineOwnership::path())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{TimelineOwnership::path()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|i1, i2| i1["creationTimestamp"]<=>i2["creationTimestamp"] }
    end

    # TimelineOwnership::issueClaimGivenTimelineAndEntity(node, target)
    def self.issueClaimGivenTimelineAndEntity(node, target)
        claim = {
            "catalystType"      => "catalyst-type:time-ownership-claim",
            "creationTimestamp" => Time.new.to_f,
            "uuid"              => SecureRandom.uuid,

            "nodeuuid"   => node["uuid"],
            "targetuuid" => target["uuid"]
        }
        TimelineOwnership::save(claim)
        claim
    end

    # TimelineOwnership::claimToString(dataclaim)
    def self.claimToString(dataclaim)
        "[starlight ownership claim] #{dataclaim["nodeuuid"]} -> #{dataclaim["targetuuid"]}"
    end

    # TimelineOwnership::getTimelineEntities(node)
    def self.getTimelineEntities(node)
        TimelineOwnership::claims()
            .select{|claim| claim["nodeuuid"] == node["uuid"] }
            .map{|claim| DataEntities::getDataEntityByUuidOrNull(claim["targetuuid"]) }
            .compact
    end

    # TimelineOwnership::getTimelinesForEntity(clique)
    def self.getTimelinesForEntity(clique)
        TimelineOwnership::claims()
            .select{|claim| claim["targetuuid"] == clique["uuid"] }
            .map{|claim| Timelines::getOrNull(claim["nodeuuid"]) }
            .compact
    end
end

class Multiverse

    # Multiverse::management()
    def self.management()
        loop {
            system("clear")
            puts "Starlight Management (root)"
            operations = [
                "make timeline",
                "make starlight path"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            break if operation.nil?
            if operation == "make timeline" then
                node = Timelines::makeTimelineInteractivelyOrNull(true)
                puts JSON.pretty_generate(node)
                Timelines::save(node)
            end
            if operation == "make starlight path" then
                node1 = Multiverse::selectOrNull()
                next if node1.nil?
                node2 = Multiverse::selectOrNull()
                next if node2.nil?
                path = Stargates::issuePathFromFirstNodeToSecondNodeOrNull(node1, node2)
                puts JSON.pretty_generate(path)
                Stargates::save(path)
            end
        }
    end

    # Multiverse::visitTimeline(node)
    def self.visitTimeline(node)
        loop {
            puts ""
            puts "uuid: #{node["uuid"]}"
            puts Timelines::timelineToString(node).green
            items = []
            items << ["rename", lambda{ 
                node["description"] = CatalystCommon::editTextUsingTextmate(node["description"]).strip
                Timelines::save(node)
            }]
            Stargates::getChildNodes(node)
                .sort{|n1, n2| n1["name"] <=> n2["name"] }
                .each{|n| items << ["[network child] #{Timelines::timelineToString(n)}", lambda{ Multiverse::visitTimeline(n) }] }

            TimelineOwnership::getTimelineEntities(node)
                .sort{|p1, p2| p1["creationTimestamp"] <=> p2["creationTimestamp"] } # "creationTimestamp" is a common attribute of all data entities
                .each{|dataentity| items << ["[dataentity] #{DataEntities::dataEntityToString(dataentity)}", lambda{ DataEntities::navigateDataEntity(dataentity) }] }

            Stargates::getParentNodes(node)
                .sort{|n1, n2| n1["name"] <=> n2["name"] }
                .each{|n| items << ["[network parent] #{Timelines::timelineToString(n)}", lambda{ Multiverse::visitTimeline(n) }] }

            items << ["select", lambda{ $EvolutionsFindXSingleton = node }]
            status = LucilleCore::menuItemsWithLambdas(items) # Boolean # Indicates whether an item was chosen
            break if !status
        }
    end

    # Multiverse::selectOrNull()
    def self.selectOrNull()
        # Version 1
        # LucilleCore::selectEntityFromListOfEntitiesOrNull("node", Timelines::timelines(), lambda {|node| Timelines::timelineToString(node) })

        # Version 2
        nodestrings = Timelines::timelines().map{|node| Timelines::timelineToString(node) }
        nodestring = CatalystCommon::chooseALinePecoStyle("node:", [""]+nodestrings)
        node = Timelines::timelines()
            .select{|node| Timelines::timelineToString(node) == nodestring }
            .first
        Multiverse::visitTimeline(node)
        return $EvolutionsFindXSingleton if $EvolutionsFindXSingleton
        if LucilleCore::askQuestionAnswerAsBoolean("Multiverse: Would you like to make a new node and return it ? ", false) then
            return Timelines::makeTimelineInteractivelyOrNull(true)
        end
        if LucilleCore::askQuestionAnswerAsBoolean("Multiverse: There is no selection, would you like to return null ? ", true) then
            return nil
        end
        Multiverse::selectOrNull()
    end

    # Multiverse::navigate()
    def self.navigate()
        # Version 1
        # LucilleCore::selectEntityFromListOfEntitiesOrNull("node", Timelines::timelines(), lambda {|node| Timelines::timelineToString(node) })

        # Version 2
        nodestrings = Timelines::timelines().map{|node| Timelines::timelineToString(node) }
        nodestring = CatalystCommon::chooseALinePecoStyle("node:", [""]+nodestrings)
        return if nodestring.strip.size == 0
        node = Timelines::timelines()
            .select{|node| Timelines::timelineToString(node) == nodestring }
            .first
        Multiverse::visitTimeline(node)
    end
end

