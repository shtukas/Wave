# encoding: UTF-8

class Synthetic

    # Synthetic::register(datetime, id, timespan)
    def self.register(datetime, id, timespan)
        entry = "#{datetime}|#{id}|#{timespan}"
        File.open("/Users/pascal/Galaxy/DataBank/Catalyst/Synthetic.log", "a"){|f| f.puts(entry) }
    end

    # Synthetic::getRecordsInTimeOrder()
    def self.getRecordsInTimeOrder()
        IO.read("/Users/pascal/Galaxy/DataBank/Catalyst/Synthetic.log")
            .lines
            .map{|line| line.strip }
            .select{|line| line.size > 0 }
            .map{|line|
                elements = line.split('|')
                {
                    "unixtime" => DateTime.parse(elements[0]).to_time.to_i,
                    "id"       => elements[1],
                    "timespan" => elements[2].to_f
                }
            }
    end

    # Synthetic::getSyntheticRecordsInTimeOrder()
    def self.getSyntheticRecordsInTimeOrder()
        Synthetic::getRecordsInTimeOrder()
            .reduce({}){|str, record|
                if str[record["id"]] then
                    str[record["id"]] << record
                else
                    str[record["id"]] = [ record ]
                end
                str
            }
            .to_a
            .select{|pair| pair[1].size == 1 }
            .map{|pair| pair[1] }
            .flatten
    end

    # Synthetic::getgetSyntheticRecordsAfterHorizon(horizon)
    def self.getgetSyntheticRecordsAfterHorizon(horizon)
        records = Synthetic::getSyntheticRecordsInTimeOrder()
        records.select{|record| record["unixtime"] >= horizon}
    end

    # Synthetic::getCumulatedTimespanAfterHorizon(horizon)
    def self.getCumulatedTimespanAfterHorizon(horizon)
        Synthetic::getgetSyntheticRecordsAfterHorizon(horizon)
            .map{|record| record["timespan"] }.inject(0, :+)
    end

    # Synthetic::getRecoveryTimeInHoursAfterHorizon(horizon)
    def self.getRecoveryTimeInHoursAfterHorizon(horizon)
        unixtime1 = horizon
        unixtime2 = Time.new.to_f
        ratio = Synthetic::getCumulatedTimespanAfterHorizon(horizon).to_f/(unixtime2-unixtime1)
        ratio*24
    end

    # Synthetic::getRecoveryTimeInHours()
    def self.getRecoveryTimeInHours()
        (1..7)
            .map{|i| Time.new.to_f - 86400*i }
            .map{|horizon| Synthetic::getRecoveryTimeInHoursAfterHorizon(horizon)}
            .max
    end

    # Synthetic::targettingCurveIdealValueAtDateTime(datetime)
    def self.targettingCurveIdealValueAtDateTime(datetime)
        t1 = DateTime.parse("2021-04-18T11:26:40Z").to_time.to_i
        t2 = DateTime.parse(datetime).to_time.to_i
        7759 - 30*((t2-t1).to_f/86400)
    end

    # Synthetic::targettingNumbers(datetime)
    def self.targettingNumbers(datetime)
        ideal = Synthetic::targettingCurveIdealValueAtDateTime(datetime)
        current = LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataBank/Catalyst/Marbles/quarks").size
        {"current" => current, "performance" => (ideal-current).to_i}
    end
end

