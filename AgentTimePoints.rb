#!/usr/bin/ruby

# encoding: UTF-8
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
require 'colorize'
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require "/Galaxy/local-resources/Ruby-Libraries/SetsOperator.rb"
require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require_relative "Bob.rb"
# -------------------------------------------------------------------------------------


# -------------------------------------------------------------------------------------

Bob::registerAgent(
    {
        "agent-name"      => "TimePoints",
        "agent-uid"       => "03a8bff4-a2a4-4a2b-a36f-635714070d1d",
        "general-upgrade" => lambda { AgentTimePoints::generalFlockUpgrade() },
        "object-command-processor" => lambda{ |object, command| AgentTimePoints::processObjectAndCommandFromCli(object, command) },
        "interface"       => lambda{ AgentTimePoints::interface() }
    }
)

# AgentTimePoints::generalFlockUpgrade()
# AgentTimePoints::processObjectAndCommandFromCli(object, command)

class AgentTimePoints

    def self.agentuuid()
        "03a8bff4-a2a4-4a2b-a36f-635714070d1d"
    end

    def self.interface()
        puts "Welcome to TimeCommitments interface"
        if LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Would you like to add a time commitment ? ") then
            TimePointsCore::issueNewPoint(
                SecureRandom.hex(8), 
                LucilleCore::askQuestionAnswerAsString("description: "), 
                LucilleCore::askQuestionAnswerAsString("hours: ").to_f, 
                LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Guardian support ? "))
        end
    end

    def self.timepointToCatalystObjectOrNull(timepoint)
        uuid = timepoint['uuid']
        ratioDone = (TimePointsCore::timepointToLiveTimespan(timepoint).to_f/3600)/timepoint["commitment-in-hours"]
        metric = nil
        if timepoint["is-running"] then
            metric = 2 - CommonsUtils::traceToMetricShift(uuid)
            if ratioDone>1 then
                message = "#{timepoint['description']} is done"
                system("terminal-notifier -title Catalyst -message '#{message}'")
                sleep 2
            end
        else
            metric =
                if ratioDone>1 then
                    0
                else
                    if timepoint['metric'] then
                        timepoint['metric']
                    else
                        0.5 + 0.1*CommonsUtils::realNumbersToZeroOne(timepoint["commitment-in-hours"], 1, 1) + 0.1*Math.exp(-ratioDone*3) + CommonsUtils::traceToMetricShift(uuid)
                    end
                end
        end
        announce = "time commitment: #{timepoint['description']} (#{ "%.2f" % (100*ratioDone) } % of #{timepoint["commitment-in-hours"]} hours done)"
        commands = ( timepoint["is-running"] ? ["stop"] : ["start"] ) + ["destroy"]
        defaultExpression = timepoint["is-running"] ? "stop" : "start"
        object  = {}
        object["uuid"]      = uuid
        object["agent-uid"] = self.agentuuid()
        object["metric"]    = metric
        object["announce"]  = announce
        object["commands"]  = commands
        object["default-expression"]     = defaultExpression
        object["metadata"]               = {}
        object["metadata"]["is-running"] = timepoint["is-running"]
        object["metadata"]["time-commitment-timepoint"] = timepoint
        object
    end

    def self.generalFlockUpgrade()
        TimePointsCore::garbageCollectionGlobal()
        TheFlock::removeObjectsFromAgent(self.agentuuid())
        objects = TimePointsCore::getTimePoints()
            .select{|timepoint| timepoint["commitment-in-hours"] > 0 }
            .map{|timepoint| AgentTimePoints::timepointToCatalystObjectOrNull(timepoint) }
            .compact
        TheFlock::addOrUpdateObjects(objects)
    end

    def self.processObjectAndCommandFromCli(object, command)
        uuid = object['uuid']
        if command == "start" then
            TimePointsCore::saveTimePoint(TimePointsCore::startTimePoint(TimePointsCore::getTimePointByUUID(uuid)))
        end
        if command == "stop" then
            TimePointsCore::saveTimePoint(TimePointsCore::stopTimePoint(TimePointsCore::getTimePointByUUID(uuid)))
        end
        if command == "destroy" then
            TimePointsCore::destroyTimePoint(TimePointsCore::getTimePointByUUID(uuid))
        end
    end
end

