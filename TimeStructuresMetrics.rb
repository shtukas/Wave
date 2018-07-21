
# encoding: UTF-8

# TimeStructuresMetrics::metric1(low, high, ratiodone)
# TimeStructuresMetrics::metric4(uuid, donemetric, lowmetric, highmetric, timestructure)

class TimeStructuresMetrics
    def self.metric1(low, high, ratiodone)
        return low if ratiodone >= 1 
        low + (high-low)*(1-ratiodone)
    end

    def self.metric4(uuid, donemetric, lowmetric, highmetric, timestructure)
        return highmetric if Chronos::isRunning(uuid)
        return donemetric if Chronos::ratioDone(uuid, timestructure["time-unit-in-days"], timestructure["time-commitment-in-hours"]) >= 1
        ratiodone1 = Chronos::ratioDone(uuid, timestructure["time-unit-in-days"], timestructure["time-commitment-in-hours"])
        ratiodone2 = Chronos::ratioDone(uuid, 1, timestructure["time-commitment-in-hours"].to_f/timestructure["time-unit-in-days"])
        TimeStructuresMetrics::metric1(lowmetric, highmetric, [ratiodone1, ratiodone2].max)
    end
end