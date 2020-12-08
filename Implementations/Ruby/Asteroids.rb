# encoding: UTF-8

class Asteroids

    # -------------------------------------------------------------------
    # Building

    # Asteroids::asteroidOrbitalTypes()
    def self.asteroidOrbitalTypes()
        [
            "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860",
            "daily-time-commitment-e1180643-fc7e-42bb-a2",
            "burner-5d333e86-230d-4fab-aaee-a5548ec4b955",
            "execution-context-fbc-837c-88a007b3cad0-837",
            "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c",
        ]
    end

    # Asteroids::makeOrbitalInteractivelyOrNull()
    def self.makeOrbitalInteractivelyOrNull()
        orbitalTypes = Asteroids::asteroidOrbitalTypes()
        orbitalType = LucilleCore::selectEntityFromListOfEntitiesOrNull("orbital type", orbitalTypes)
        return nil if orbitalType.nil?
        if orbitalType == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860" then
            return {
                "type" => "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860"
            }
        end
        if orbitalType == "daily-time-commitment-e1180643-fc7e-42bb-a2" then
            return {
                "type" => "daily-time-commitment-e1180643-fc7e-42bb-a2",
                "time-commitment-in-hours" => LucilleCore::askQuestionAnswerAsString("time commitment in hours: ").to_f
            }
        end
        if orbitalType == "burner-5d333e86-230d-4fab-aaee-a5548ec4b955" then
            return {
                "type" => "burner-5d333e86-230d-4fab-aaee-a5548ec4b955"
            }
        end
        if orbitalType == "execution-context-fbc-837c-88a007b3cad0-837" then
            return {
                "type" => "execution-context-fbc-837c-88a007b3cad0-837"
            }
        end
        if orbitalType == "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c" then
            return {
                "type" => "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c"
            }
        end
        raise "ef349b18-55ed-4fdb-abb0-1014f752416a"
    end

    # Asteroids::issueAsteroidInteractivelyOrNull()
    def self.issueAsteroidInteractivelyOrNull()
        description = LucilleCore::askQuestionAnswerAsString("asteroid description: ")
        return nil if (description == "")
        orbital = Asteroids::makeOrbitalInteractivelyOrNull()
        return nil if orbital.nil?
        asteroid = {
            "uuid"        => SecureRandom.hex,
            "nyxNxSet"    => "b66318f4-2662-4621-a991-a6b966fb4398",
            "unixtime"    => Time.new.to_f,
            "orbital"     => orbital,
            "description" => description
        }
        NyxObjects2::put(asteroid)
        asteroid
    end

    # Asteroids::issueDatapointAndAsteroidInteractivelyOrNull()
    def self.issueDatapointAndAsteroidInteractivelyOrNull()
        datapoint = Patricia::issueNewDatapointOrNull()
        return if datapoint.nil?
        orbital = Asteroids::makeOrbitalInteractivelyOrNull()
        return nil if orbital.nil?
        asteroid = {
            "uuid"       => SecureRandom.hex,
            "nyxNxSet"   => "b66318f4-2662-4621-a991-a6b966fb4398",
            "unixtime"   => Time.new.to_f,
            "orbital"    => orbital,
        }
        NyxObjects2::put(asteroid)
        Arrows::issueOrException(asteroid, datapoint)
        asteroid
    end

    # Asteroids::issueAsteroidInboxFromTarget(target)
    def self.issueAsteroidInboxFromTarget(target)
        orbital = {
            "type" => "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860"
        }
        asteroid = {
            "uuid"     => SecureRandom.uuid,
            "nyxNxSet" => "b66318f4-2662-4621-a991-a6b966fb4398",
            "unixtime" => Time.new.to_f,
            "orbital"  => orbital,
        }
        NyxObjects2::put(asteroid)
        Arrows::issueOrException(asteroid, target)
        asteroid
    end

    # Asteroids::issueAsteroidBurnerFromTarget(target)
    def self.issueAsteroidBurnerFromTarget(target)
        orbital = {
            "type" => "burner-5d333e86-230d-4fab-aaee-a5548ec4b955"
        }
        asteroid = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "b66318f4-2662-4621-a991-a6b966fb4398",
            "unixtime"   => Time.new.to_f,
            "orbital"    => orbital,
        }
        NyxObjects2::put(asteroid)
        Arrows::issueOrException(asteroid, target)
        asteroid
    end

    # -------------------------------------------------------------------
    # Data Extraction

    # Asteroids::asteroids()
    def self.asteroids()
        NyxObjects2::getSet("b66318f4-2662-4621-a991-a6b966fb4398")
    end

    # Asteroids::getAsteroidOrNull(uuid)
    def self.getAsteroidOrNull(uuid)
        object = NyxObjects2::getOrNull(uuid)
        return nil if object.nil?
        return nil if (object["nyxNxSet"] != "b66318f4-2662-4621-a991-a6b966fb4398")
        object
    end

    # Asteroids::asteroidOrbitalAsUserFriendlyString(orbital)
    def self.asteroidOrbitalAsUserFriendlyString(orbital)
        return "📥"  if orbital["type"] == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860"
        return "💫"  if orbital["type"] == "daily-time-commitment-e1180643-fc7e-42bb-a2"
        return "🔥"  if orbital["type"] == "burner-5d333e86-230d-4fab-aaee-a5548ec4b955"
        return "⏱ " if orbital["type"] == "execution-context-fbc-837c-88a007b3cad0-837"
        return "✨"  if orbital["type"] == "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c"
    end

    # Asteroids::asteroidDescription(asteroid)
    def self.asteroidDescription(asteroid)
        targets = Arrows::getTargetsForSource(asteroid)
        if asteroid["description"] then
            return "#{asteroid["description"]}"
        end
        if targets.size == 0 then
            return "no description / no target"
        end 
        if targets.size == 1 then
            return Patricia::toString(targets[0])
        end 
        return "(#{targets.size} targets)"
    end

    # Asteroids::toString(asteroid)
    def self.toString(asteroid)
        uuid = asteroid["uuid"]
        isRunning = Runner::isRunning?(uuid)
        p1 = "[asteroid]"
        p2 = " #{Asteroids::asteroidOrbitalAsUserFriendlyString(asteroid["orbital"])}"
        p3 = " #{Asteroids::asteroidDescription(asteroid)}"
        p4 =
            if isRunning then
                " (running for #{(Runner::runTimeInSecondsOrNull(uuid).to_f/3600).round(2)} hours)"
            else
                ""
            end

        "#{p1}#{p2}#{p3}#{p4}"
    end

    # Asteroids::asteroidDailyTimeCommitmentNumbers(asteroid)
    def self.asteroidDailyTimeCommitmentNumbers(asteroid)
        return "" if asteroid["orbital"]["type"] != "daily-time-commitment-e1180643-fc7e-42bb-a2"
        commitmentInHours = asteroid["orbital"]["time-commitment-in-hours"]
        ratio = BankExtended::recoveredDailyTimeInHours(asteroid["uuid"]).to_f/commitmentInHours
        return " (#{asteroid["orbital"]["time-commitment-in-hours"]} hours, #{(100*ratio).round(2)} % completed)"
    end

    # Asteroids::asteroidsDailyTimeCommitments()
    def self.asteroidsDailyTimeCommitments()
        Asteroids::asteroids()
            .select{|asteroid| asteroid["orbital"]["type"] == "daily-time-commitment-e1180643-fc7e-42bb-a2" }
    end

    # Asteroids::selectOneDailyTimeCommitmentOrNull()
    def self.selectOneDailyTimeCommitmentOrNull()
        asteroids = Asteroids::asteroidsDailyTimeCommitments()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("asteroid", asteroids, lambda{|asteroid| Asteroids::toString(asteroid) })
    end

    # Asteroids::getNx39Sequence(sequence)
    def self.getNx39Sequence(sequence)
        return [] if sequence.empty?
        last = sequence.last
        targets = TargetOrdinals::getTargetsForSourceInOrdinalOrder(last)
        return sequence if targets.empty?
        sequence + [targets.first]
    end

    # Asteroids::nx39ToString(uuid, sequence)
    def self.nx39ToString(uuid, sequence)
        strs = sequence.map{|object| Patricia::toString(object) }
        # Turning
        # [asteroid] 📥 [quark] [aion-location] How I Made a Self-Quoting Tweet / [quark] [aion-location] How I Made a Self-Quoting Tweet
        # into
        # [asteroid] 📥 / [quark] [aion-location] How I Made a Self-Quoting Tweet
        if strs.size >= 2 then
            if strs[0][-strs[1].size, strs[1].size] == strs[1] then
                strs[0] = strs[0][0, strs[0].size-strs[1].size].strip
            end
        end
        strs.join(" / ") + Runner::runTimeAsString(uuid, " ")
    end

    # -------------------------------------------------------------------
    # Catalyst Objects

    # Asteroids::metric(asteroid)
    def self.metric(asteroid)

        if asteroid["orbital"]["type"] == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860" then
            return 0.70
        end

        if asteroid["orbital"]["type"] == "daily-time-commitment-e1180643-fc7e-42bb-a2" then
            return ExecutionContexts::metric2(asteroid["uuid"], asteroid["orbital"]["time-commitment-in-hours"], asteroid["uuid"])
        end

        if asteroid["orbital"]["type"] == "burner-5d333e86-230d-4fab-aaee-a5548ec4b955" then
            return ExecutionContexts::metric2("ExecutionContext-47C73AE6-D40B-4099-B79C-3373E5070204", 1, asteroid["uuid"])
        end

        if asteroid["orbital"]["type"] == "execution-context-fbc-837c-88a007b3cad0-837" then
            return ExecutionContexts::metric2("ExecutionContext-62CA63E8-190D-4C05-AA0F-027A999003C0", 2, asteroid["uuid"])
        end

        if asteroid["orbital"]["type"] == "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c" then
            return ExecutionContexts::metric2("ExecutionContext-2943891F-27BC-4C82-B29E-4254389A86BC", 1, asteroid["uuid"])
        end

        puts asteroid
        raise "[Asteroids] error: 46b84bdb"
    end

    # Asteroids::asteroidToCalalystObjects(asteroid)
    def self.asteroidToCalalystObjects(asteroid)

        return [] if !DoNotShowUntil::isVisible(asteroid["uuid"])

        if asteroid["activeDays"] and !asteroid["activeDays"].include?(Time.new.wday) then
            return []
        end

        asteroidmetric = Asteroids::metric(asteroid)

        # We take the first one and then the active others
        TargetOrdinals::getTargetsForSourceInOrdinalOrder(asteroid)
            .select{|target|
                uuid = "#{asteroid["uuid"]}-#{target["uuid"]}"
                DoNotShowUntil::isVisible(uuid)
            }
            .first(3)
            .map{|target|
                uuid = "#{asteroid["uuid"]}-#{target["uuid"]}"
                metric = asteroidmetric - 0.001*BankExtended::recoveredDailyTimeInHours(uuid)
                isRunning = Runner::isRunning?(uuid)
                metric = 1 if isRunning
                {
                    "uuid"             => uuid,
                    "body"             => Asteroids::nx39ToString(uuid, Asteroids::getNx39Sequence([asteroid, target])),
                    "metric"           => metric,
                    "landing"          => lambda { Patricia::landing(target) },
                    "nextNaturalStep"  => lambda { Asteroids::asteroidTargetNaturalNextOperation(asteroid, target, uuid) },
                    "isRunning"        => isRunning,
                    "isRunningForLong" => (lambda {
                        return false if !Runner::isRunning?(uuid)
                        ( Runner::runTimeInSecondsOrNull(uuid) || 0 ) > 3600
                    }).call(),
                    "x-asteroid"       => asteroid,
                }
            }
    end

    # Asteroids::catalystObjects()
    def self.catalystObjects()
        struct = Asteroids::asteroids()
                    .reduce({"objects" => [], "streamCounter" => 0}) {|struct, asteroid|
                        if asteroid["orbital"]["type"] != "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c" then
                            {
                                "objects" => struct["objects"] + Asteroids::asteroidToCalalystObjects(asteroid), 
                                "streamCounter" => struct["streamCounter"]
                            }
                        else
                            if struct["streamCounter"] < 10 then
                                {
                                    "objects" => struct["objects"] + Asteroids::asteroidToCalalystObjects(asteroid), 
                                    "streamCounter" => struct["streamCounter"]+1
                                }
                            else
                                {
                                    "objects" => struct["objects"], 
                                    "streamCounter" => struct["streamCounter"]+1
                                }
                            end

                        end
                    }
        struct["objects"]
    end

    # -------------------------------------------------------------------
    # Operations

    # Asteroids::reOrbitalOrNothing(asteroid)
    def self.reOrbitalOrNothing(asteroid)
        orbital = Asteroids::makeOrbitalInteractivelyOrNull()
        return if orbital.nil?
        asteroid["orbital"] = orbital
        puts JSON.pretty_generate(asteroid)
        NyxObjects2::put(asteroid)
    end

    # Asteroids::asteroidReceivesTime(asteroid, timespanInSeconds)
    def self.asteroidReceivesTime(asteroid, timespanInSeconds)
        puts "Adding #{timespanInSeconds} seconds to '#{Asteroids::toString(asteroid)}'"
        Bank::put(asteroid["uuid"], timespanInSeconds) # This also feeds the asteroids that are their own execution context, eg: the daily time commitments. 

        puts "Adding #{timespanInSeconds} seconds to #{asteroid["orbital"]["type"]}"
        Bank::put(asteroid["orbital"]["type"], timespanInSeconds)

        if asteroid["orbital"]["type"] == "inbox-cb1e2cb7-4264-4c66-acef-687846e4ff860" then
            puts "Adding #{timespanInSeconds} seconds to ExecutionContext-62CA63E8-190D-4C05-AA0F-027A999003C0" # The original context
            Bank::put("ExecutionContext-62CA63E8-190D-4C05-AA0F-027A999003C0", timespanInSeconds)
        end
        if asteroid["orbital"]["type"] == "execution-context-fbc-837c-88a007b3cad0-837" then
            puts "Adding #{timespanInSeconds} seconds to ExecutionContext-62CA63E8-190D-4C05-AA0F-027A999003C0" # The original context
            Bank::put("ExecutionContext-62CA63E8-190D-4C05-AA0F-027A999003C0", timespanInSeconds)
        end
        if asteroid["orbital"]["type"] == "burner-5d333e86-230d-4fab-aaee-a5548ec4b955" then
            puts "Adding #{timespanInSeconds} seconds to ExecutionContext-47C73AE6-D40B-4099-B79C-3373E5070204"
            Bank::put("ExecutionContext-47C73AE6-D40B-4099-B79C-3373E5070204", timespanInSeconds)
        end
        if asteroid["orbital"]["type"] == "stream-78680b9b-a450-4b7f-8e15-d61b2a6c5f7c" then
            puts "Adding #{timespanInSeconds} seconds to ExecutionContext-2943891F-27BC-4C82-B29E-4254389A86BC"
            Bank::put("ExecutionContext-2943891F-27BC-4C82-B29E-4254389A86BC", timespanInSeconds)
        end
    end

    # Asteroids::startAsteroidIfNotRunning(asteroid)
    def self.startAsteroidIfNotRunning(asteroid)
        return if Runner::isRunning?(asteroid["uuid"])
        puts "start asteroid: #{Asteroids::toString(asteroid)}"
        Runner::start(asteroid["uuid"])
    end

    # Asteroids::stopAsteroidIfRunning(asteroid)
    def self.stopAsteroidIfRunning(asteroid)
        return if !Runner::isRunning?(asteroid["uuid"])
        timespan = Runner::stop(asteroid["uuid"])
        return if timespan.nil?
        timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
        Asteroids::asteroidReceivesTime(asteroid, timespan)
    end

    # Asteroids::diveAsteroidOrbitalType(orbitalType)
    def self.diveAsteroidOrbitalType(orbitalType)
        loop {
            system("clear")
            asteroids = Asteroids::asteroids().select{|asteroid| asteroid["orbital"]["type"] == orbitalType }
            asteroid = LucilleCore::selectEntityFromListOfEntitiesOrNull("asteroid", asteroids, lambda{|asteroid| Asteroids::toString(asteroid) })
            break if asteroid.nil?
            Asteroids::landing(asteroid)
        }
    end

    # Asteroids::getAsteroidTargetDestinationOrNull(asteroid)
    def self.getAsteroidTargetDestinationOrNull(asteroid)
        recipient = nil
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["move to a target", "move to a parent", "move to a Patricia selected element"]) 
        return nil if option.nil?
        if option == "move to a target" then
            recipient = Patricia::selectOneTargetOfThisObjectOrNull(asteroid)
        end
        if option == "move to a parent" then
            recipient = Patricia::selectOneParentOfThisObjectOrNull(asteroid)
        end
        if option == "move to a Patricia selected element" then
            recipient = Patricia::architect()
        end
        recipient
    end

    # Asteroids::moveAsteroidTarget(asteroid, target)
    def self.moveAsteroidTarget(asteroid, target)
        puts "moving: #{Patricia::toString(target)}"
        if Patricia::isQuark(target) and target["type"] == "aion-location" and target["description"].nil? then
            description = LucilleCore::askQuestionAnswerAsString("target description: ")
            if description.size > 0 then
                Quarks::setDescription(target, description)
            end
        end
        if Patricia::isNGX15(target) and target["type"] == "aion-location" and target["description"].nil? then
            description = LucilleCore::askQuestionAnswerAsString("target description: ")
            if description.size > 0 then
                target["description"] = description
                NyxObjects2::put(target)
            end
        end
        destination = Asteroids::getAsteroidTargetDestinationOrNull(asteroid)
        return if destination.nil?
        return if destination["uuid"] == asteroid["uuid"]
        Arrows::issueOrException(destination, target)
        Arrows::unlink(asteroid, target)
        Patricia::landing(target)
    end

    # Asteroids::moveSelectedAsteroidTargets(asteroid)
    def self.moveSelectedAsteroidTargets(asteroid)
        selected = Patricia::selectZeroOrMoreTargetsFromThisObject(asteroid)
        return if selected.size == 0
        destination = Asteroids::getAsteroidTargetDestinationOrNull(asteroid)
        return if destination.nil?
        return if destination["uuid"] == asteroid["uuid"]
        selected.each{|target|
            Arrows::issueOrException(destination, target)
            Arrows::unlink(asteroid, target)
        }
    end

    # Asteroids::asteroidTargetNaturalNextOperation(asteroid, target, asteroidTargetUUID)
    def self.asteroidTargetNaturalNextOperation(asteroid, target, asteroidTargetUUID)
        addTime = lambda {|asteroid, asteroidTargetUUID, timespan|
            puts "Adding #{timespan} seconds to asteroid/target runId '#{asteroidTargetUUID}'"
            Bank::put(asteroidTargetUUID, timespan)
            Asteroids::asteroidReceivesTime(asteroid, timespan)
        }
        if !Runner::isRunning?(asteroidTargetUUID) then
            # Is not running
            Runner::start(asteroidTargetUUID)
            Patricia::open1(Asteroids::getNx39Sequence([asteroid, target]).last)
            menuitems = LCoreMenuItemsNX1.new()
            menuitems.item("keep running".yellow, lambda {})
            menuitems.item("stop".yellow, lambda { 
                timespan = Runner::stop(asteroidTargetUUID)
                timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
                addTime.call(asteroid, asteroidTargetUUID, timespan)
            })
            menuitems.item("stop ; hide for n days".yellow, lambda { 
                timespan = Runner::stop(asteroidTargetUUID)
                timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
                addTime.call(asteroid, asteroidTargetUUID, timespan)
                n = LucilleCore::askQuestionAnswerAsString("hide duration in days: ").to_f
                DoNotShowUntil::setUnixtime(asteroidTargetUUID, Time.new.to_i + n*86400)
            })
            menuitems.item("target landing".yellow, lambda { 
                Patricia::landing(target)
            })
            menuitems.item("stop ; move target".yellow, lambda { 
                timespan = Runner::stop(asteroidTargetUUID)
                timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
                addTime.call(asteroid, asteroidTargetUUID, timespan)
                Asteroids::moveAsteroidTarget(asteroid, target)
            })
            menuitems.item("stop ; destroy target".yellow,lambda {
                timespan = Runner::stop(asteroidTargetUUID)
                timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
                addTime.call(asteroid, asteroidTargetUUID, timespan)
                Patricia::destroy(target)
            })
            menuitems.item("stop ; re-orbital asteroid".yellow, lambda { 
                Asteroids::reOrbitalOrNothing(asteroid)
            })
            status = menuitems.promptAndRunSandbox()
        else
            # Is running
            menuitems = LCoreMenuItemsNX1.new()
            menuitems.item("stop".yellow, lambda {
                timespan = Runner::stop(asteroidTargetUUID)
                timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
                addTime.call(asteroid, asteroidTargetUUID, timespan)
            })
            menuitems.item("stop ; hide for n days".yellow, lambda { 
                timespan = Runner::stop(asteroidTargetUUID)
                timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
                addTime.call(asteroid, asteroidTargetUUID, timespan)
                n = LucilleCore::askQuestionAnswerAsString("hide duration in days: ").to_f
                DoNotShowUntil::setUnixtime(asteroidTargetUUID, Time.new.to_i + n*86400)
            })
            menuitems.item("stop ; move target".yellow, lambda {
                timespan = Runner::stop(asteroidTargetUUID)
                timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
                addTime.call(asteroid, asteroidTargetUUID, timespan)
                Asteroids::moveAsteroidTarget(asteroid, target)
            })
            menuitems.item("stop ; destroy target".yellow, lambda {
                timespan = Runner::stop(asteroidTargetUUID)
                timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
                addTime.call(asteroid, asteroidTargetUUID, timespan)
                Patricia::destroy(target)
            })
            menuitems.item("stop ; re-orbital asteroid".yellow, lambda { 
                Asteroids::reOrbitalOrNothing(asteroid)
            })
            menuitems.item("target landing".yellow, lambda { 
                Patricia::landing(target)
            })
            status = menuitems.promptAndRunSandbox()
        end
    end

    # Asteroids::landing(asteroid)
    def self.landing(asteroid)
        loop {

            asteroid = Asteroids::getAsteroidOrNull(asteroid["uuid"])
            return if asteroid.nil?

            system("clear")

            mx = LCoreMenuItemsNX1.new()

            Miscellaneous::horizontalRule()

            puts Asteroids::toString(asteroid)

            puts "uuid: #{asteroid["uuid"]}".yellow
            puts "orbital: #{JSON.generate(asteroid["orbital"])}".yellow
            puts "activeDays: #{JSON.generate(asteroid["activeDays"])}".yellow
            puts "bank value: #{Bank::value(asteroid["uuid"])}".yellow
            puts "BankExtended::recoveredDailyTimeInHours: #{BankExtended::recoveredDailyTimeInHours(asteroid["uuid"])}".yellow
            puts "metric: #{Asteroids::metric(asteroid)}".yellow

            unixtime = DoNotShowUntil::getUnixtimeOrNull(asteroid["uuid"])
            if unixtime and (Time.new.to_i < unixtime) then
                puts "DoNotShowUntil: #{Time.at(unixtime).to_s}".yellow
            end

            puts ""

            Patricia::mxTargetting(asteroid, mx)

            puts ""

            mx.item("update asteroid description".yellow, lambda { 
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                return if description == ""
                asteroid["description"] = description
                NyxObjects2::put(asteroid)
                KeyValueStore::destroy(nil, "f16f78bd-c5a1-490e-8f28-9df73f43733d:#{asteroid["uuid"]}")
            })

            puts ""

            mx.item("start target".yellow, lambda {
                target = Patricia::selectOneTargetOrNullDefaultToSingletonWithConfirmation(asteroid)
                return if target.nil?
                uuid = "#{asteroid["uuid"]}-#{target["uuid"]}"
                Runner::start(uuid)
            })

            puts ""

            mx.item(
                "re-orbital".yellow,
                lambda { Asteroids::reOrbitalOrNothing(asteroid) }
            )

            mx.item("show json".yellow, lambda {
                puts JSON.pretty_generate(asteroid)
                LucilleCore::pressEnterToContinue()
            })

            mx.item("stop ; hide for n days".yellow, lambda { 
                Asteroids::stopAsteroidIfRunning(asteroid)
                n = LucilleCore::askQuestionAnswerAsString("hide duration in days: ").to_f
                DoNotShowUntil::setUnixtime(asteroid["uuid"], Time.new.to_i + n*86400)
            })

            mx.item( "add time".yellow, lambda {
                timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
                Asteroids::asteroidReceivesTime(asteroid, timeInHours*3600)
            })

            puts ""

            Patricia::mxTargetsManagement(asteroid, mx)

            puts ""

            mx.item("select targets ; move them".yellow, lambda {
                Asteroids::moveSelectedAsteroidTargets(asteroid)
            })

            mx.item("select and destroy target".yellow, lambda {
                target = Patricia::selectOneTargetOrNullDefaultToSingletonWithConfirmation(asteroid)
                return if target.nil?
                Patricia::destroy(target)
            })

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status

        }

        SelectionLookupDataset::updateLookupForAsteroid(asteroid)
    end

    # Asteroids::main()
    def self.main()
        loop {
            system("clear")
            options = [
                "make new asteroid",
                "dive asteroids"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            break if option.nil?
            if option == "make new asteroid" then
                asteroid = Asteroids::issueAsteroidInteractivelyOrNull()
                next if asteroid.nil?
                puts JSON.pretty_generate(asteroid)
                Asteroids::landing(asteroid)
            end
            if option == "dive asteroids" then
                loop {
                    system("clear")
                    orbitalType = LucilleCore::selectEntityFromListOfEntitiesOrNull("asteroid", Asteroids::asteroidOrbitalTypes())
                    break if orbitalType.nil?
                    Asteroids::diveAsteroidOrbitalType(orbitalType)
                }
            end
        }
    end

    # ------------------------------------------------------------------
end
