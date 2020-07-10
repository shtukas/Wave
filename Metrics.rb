
# encoding: UTF-8

# require_relative "Metrics.rb"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

# -----------------------------------------------------------------

class Metrics

    # Metrics::best7SamplesTimeRatioOverPeriod(pinguuid, timespanInSeconds)
    def self.best7SamplesTimeRatioOverPeriod(pinguuid, timespanInSeconds)
        (1..7)
            .map{|i|
                lookupPeriodInSeconds = timespanInSeconds*(i.to_f/7)
                timedone = Bank::valueOverTimespan(pinguuid, lookupPeriodInSeconds)
                timedone.to_f/lookupPeriodInSeconds
            }
            .max
    end

    # Metrics::recoveredDailyTimeInHours(pinguuid)
    def self.recoveredDailyTimeInHours(pinguuid)
        (Metrics::best7SamplesTimeRatioOverPeriod(pinguuid, 86400*7)*86400).to_f/3600
    end

    # Metrics::targetRatioThenFall(basemetric, pinguuid, dailyExpectationInSeconds)
    def self.targetRatioThenFall(basemetric, pinguuid, dailyExpectationInSeconds)
        recoveredTimeInHours = Metrics::recoveredDailyTimeInHours(pinguuid)
        expectedTimeInHours = dailyExpectationInSeconds.to_f/3600
        if recoveredTimeInHours < expectedTimeInHours then
            basemetric
        else
            extraTimeInHours = recoveredTimeInHours-expectedTimeInHours
            0.2 + (basemetric-0.2)*Math.exp(-0.5*extraTimeInHours)
        end
    end

    # Metrics::fall(basemetric, pinguuid)
    def self.fall(basemetric, pinguuid)
        Metrics::recoveredDailyTimeInHours(pinguuid)
        0.2 + (basemetric-0.2)*Math.exp(-0.5*Metrics::recoveredDailyTimeInHours(pinguuid))
    end

end