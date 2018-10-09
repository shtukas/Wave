
# encoding: UTF-8

require "json"

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

# ----------------------------------------------------------------------------------

=begin

Structure of individual objects metadata
{
    "objectuuid"                                : UUID
    "object-lightthread-link-2793690c"          : nil | LightThread UUID
    "nsx-cycle-unixtime-20181005-085102-091691" : nil | Unixitime
    "light-thread-running-status"               : nil | CatalystObjectLightThreadRunningStatus
}

CatalystObjectLightThreadRunningStatus {
    "light-thread-uuid" : UUID
    "start-unixtime"    : Unixtime
}

=end

class NSXCatalystMetadataInterface

    # -----------------------------------------------------------------------
    # CatalystObjectLightThreadRunningStatus


    # NSXCatalystMetadataInterface::setLightThreadRunningStatus(catalystObjectUUID, lightthreaduuid, startunixtime)
    def self.setLightThreadRunningStatus(catalystObjectUUID, lightthreaduuid, startunixtime)
        metadata = NSXCatalystMetadataOperator::getMetadataForObject(catalystObjectUUID)
        metadata["light-thread-running-status"] = {
            "light-thread-uuid" => lightthreaduuid,
            "start-unixtime"    => startunixtime
        }
        NSXCatalystMetadataOperator::setMetadataForObject(catalystObjectUUID, metadata)
    end

    # NSXCatalystMetadataInterface::getLightThreadRunningStatusOrNUll(catalystObjectUUID)
    def self.getLightThreadRunningStatusOrNUll(catalystObjectUUID)
        metadata = NSXCatalystMetadataOperator::getMetadataForObject(catalystObjectUUID)
        metadata["light-thread-running-status"]
    end

    # NSXCatalystMetadataInterface::unSetLightThreadRunningStatus(catalystObjectUUID)
    def self.unSetLightThreadRunningStatus(catalystObjectUUID)
        metadata = NSXCatalystMetadataOperator::getMetadataForObject(catalystObjectUUID)
        metadata.delete("light-thread-running-status")
        NSXCatalystMetadataOperator::setMetadataForObject(catalystObjectUUID, metadata)
    end

    # -----------------------------------------------------------------------
    # Catalyst Object LightThread Link

    # NSXCatalystMetadataInterface::setLightThread(catalystObjectUUID, lightThreadUUID)
    def self.setLightThread(catalystObjectUUID, lightThreadUUID)
        metadata = NSXCatalystMetadataOperator::getMetadataForObject(catalystObjectUUID)
        metadata["object-lightthread-link-2793690c"] = lightThreadUUID
        NSXCatalystMetadataOperator::setMetadataForObject(catalystObjectUUID, metadata)
    end

    # NSXCatalystMetadataInterface::unSetLightThread(catalystObjectUUID)
    def self.unSetLightThread(catalystObjectUUID)
        metadata = NSXCatalystMetadataOperator::getMetadataForObject(catalystObjectUUID)
        metadata.delete("object-lightthread-link-2793690c")
        NSXCatalystMetadataOperator::setMetadataForObject(catalystObjectUUID, metadata)        
    end

    # NSXCatalystMetadataInterface::getLightThreadUUIDOrNull(catalystObjectUUID)
    def self.getLightThreadUUIDOrNull(catalystObjectUUID)
        metadata = NSXCatalystMetadataOperator::getMetadataForObject(catalystObjectUUID)
        metadata["object-lightthread-link-2793690c"]       
    end

    # NSXCatalystMetadataInterface::lightThreadCatalystObjectUUIDs(lightThreadUUID)
    def self.lightThreadCatalystObjectUUIDs(lightThreadUUID)
        NSXCatalystMetadataOperator::getAllMetadataObjects()
            .select{|metadata| metadata["object-lightthread-link-2793690c"]==lightThreadUUID }
            .map{|metadata| metadata["objectuuid"] }
    end

    # NSXCatalystMetadataInterface::lightThreadsCatalystObjectUUIDs()
    def self.lightThreadsCatalystObjectUUIDs()
        NSXCatalystMetadataOperator::getAllMetadataObjects()
            .select{|metadata| metadata["object-lightthread-link-2793690c"] }
            .map{|metadata| metadata["objectuuid"] }
    end

    # -----------------------------------------------------------------------
    # Cycle Unixtimes

    # NSXCatalystMetadataInterface::setMetricCycleUnixtimeForObject(objectuuid,  unixtime)
    def self.setMetricCycleUnixtimeForObject(objectuuid,  unixtime)
        metadata = NSXCatalystMetadataOperator::getMetadataForObject(objectuuid)
        metadata["nsx-cycle-unixtime-20181005-085102-091691"] =  [NSXMiscUtils::currentDay(), unixtime]
        NSXCatalystMetadataOperator::setMetadataForObject(objectuuid, metadata)        
    end

    # NSXCatalystMetadataInterface::unSetMetricCycleUnixtimeForObject(objectuuid)
    def self.unSetMetricCycleUnixtimeForObject(objectuuid)
        metadata = NSXCatalystMetadataOperator::getMetadataForObject(objectuuid)
        metadata.delete("nsx-cycle-unixtime-20181005-085102-091691")     
        NSXCatalystMetadataOperator::setMetadataForObject(objectuuid, metadata)
    end    

    # NSXCatalystMetadataInterface::getMetricCycleUnixtimeForObjectOrNull(objectuuid)
    def self.getMetricCycleUnixtimeForObjectOrNull(objectuuid)
        metadata = NSXCatalystMetadataOperator::getMetadataForObject(objectuuid)
        pair = metadata["nsx-cycle-unixtime-20181005-085102-091691"]
        return nil if pair.nil?
        (pair[0] == NSXMiscUtils::currentDay()) ? pair[1] : nil
    end

end
