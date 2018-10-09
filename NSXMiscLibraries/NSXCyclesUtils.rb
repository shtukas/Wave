
# encoding: UTF-8

class NSXCyclesUtils
    # NSXCyclesUtils::updateObjectWithCycleMetricIfNeeded(object)
    def self.updateObjectWithCycleMetricIfNeeded(object)
        return object if object["is-running"]
        return object if object["metric"] >= 1
        unixtime = NSXCatalystMetadataInterface::getMetricCycleUnixtimeForObjectOrNull(object["uuid"])
        return object if unixtime.nil?
        return object if (Time.new.to_i-unixtime)>=3600
        object["metric"] = 0 # unlike what may have happened before, we just kill the object for an hour
        object[":metric-updated-by:NSXCyclesUtils::updateObjectWithCycleMetricIfNeeded:"] = true
        object
    end
end
