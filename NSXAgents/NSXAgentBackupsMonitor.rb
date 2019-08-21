#!/usr/bin/ruby

# encoding: UTF-8
require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require "time"

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/Torr.rb"
=begin
    Torr::event(repositorylocation, collectionuuid, mass)
    Torr::weight(repositorylocation, collectionuuid, stabililityPeriodInSeconds, simulationWeight = 0)
    Torr::metric(repositorylocation, collectionuuid, stabililityPeriodInSeconds, targetWeight, metricAtZero, metricAtTarget)
=end

# -------------------------------------------------------------------------------------

$NSXAgentBackupsMonitorScriptnames = [ # Here we assume that they are all in the Backups-SubSystem folder
    "lucille18-to-EnergyGrid",
    "EnergyGrid-to-Venus",
    "Earth-to-Jupiter",
    "Saturn-to-Pluto"
]

$NSXAgentBackupsMonitorScriptnamesToPeriodInDays = {
    "lucille18-to-EnergyGrid" => 2,
    "EnergyGrid-to-Venus" => 7,
    "Earth-to-Jupiter" => 8,
    "Saturn-to-Pluto" => 10
}


class NSXAgentBackupsMonitor

    # NSXAgentBackupsMonitor::agentuuid()
    def self.agentuuid()
        "63027c23-6131-4230-b49b-d3f23aa5ff54"
    end

    def self.scriptNameToLastUnixtime(sname)
        filename = "/Galaxy/DataBank/Backup-Logs/#{sname}.log"
        IO.read(filename).to_i
    end

    def self.scriptNameToNextOperationUnixtime(scriptname)
        NSXAgentBackupsMonitor::scriptNameToLastUnixtime(scriptname) + $NSXAgentBackupsMonitorScriptnamesToPeriodInDays[scriptname]*86400
    end

    def self.scriptNameToIsDueFlag(scriptname)
        Time.new.to_i > NSXAgentBackupsMonitor::scriptNameToNextOperationUnixtime(scriptname)
    end

    def self.scriptNameToCatalystObjectOrNull(scriptname)
        return nil if !NSXAgentBackupsMonitor::scriptNameToIsDueFlag(scriptname)
        uuid = Digest::SHA1.hexdigest("60507ff5-adce-4444-9e57-c533efb01136:#{scriptname}")
        {
            "uuid"               => uuid,
            "agentuid"           => "9fad55cf-3f41-45ae-b480-5cbef40ce57f",
            "metric"             => 0.53,
            "announce"           => "[Backups Monitor] /Galaxy/LucilleOS/Backups-SubSystem/#{scriptname}",
            "commands"           => [],
            "service-port"       => 12345
        }
    end

    # NSXAgentBackupsMonitor::getObjects()
    def self.getObjects()
        NSXAgentBackupsMonitor::getAllObjects()
    end

    # NSXAgentBackupsMonitor::getAllObjects()
    def self.getAllObjects()
        $NSXAgentBackupsMonitorScriptnames
            .map{|scriptname|
                NSXAgentBackupsMonitor::scriptNameToCatalystObjectOrNull(scriptname)
            }
            .compact
    end

    # NSXAgentBackupsMonitor::processObjectAndCommand(object, command)
    def self.processObjectAndCommand(object, command)
        if command == "open" then
            return 
        end
    end
end

