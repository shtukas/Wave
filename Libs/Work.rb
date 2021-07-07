
# encoding: UTF-8

# -----------------------------------------------------------------------

class Work

    # --------------------------------------------------

    # Work::isWorkTime()
    def self.isWorkTime()
        b1 = (9 <= Time.new.hour  and Time.new.hour < 17)
        b2 = [1,2,3,4,5].include?(Time.new.wday)
        b1 and b2
    end

    # Work::shouldDisplayWork()
    def self.shouldDisplayWork()
        return false if (KeyValueStore::getOrNull(nil, "ce621184-51d7-456a-8ad1-20e7d9acb350:#{Utils::today()}") == "ns:false")
        return false if !DoNotShowUntil::isVisible("WORK-E4A9-4BCD-9824-1EEC4D648408")
        Work::isWorkTime()
    end

    # Work::ns16s()
    def self.ns16s()
        return [] if !Work::shouldDisplayWork()
        uuid = "WORK-E4A9-4BCD-9824-1EEC4D648408"
        [
            {
                "uuid"     => uuid,
                "announce" => "[work] (rt: #{"%4.2f" % BankExtended::stdRecoveredDailyTimeInHours(uuid)}) 👩🏻‍💻",
                "access"   => lambda { 
                    DetachedRunning::issueNew2("[work]", Time.new.to_i, ["WORK-E4A9-4BCD-9824-1EEC4D648408"])
                },
                "done"     => lambda { }
            }
        ]
    end
end
