
# encoding: UTF-8

# -----------------------------------------------------------------------

class Work

    # ---------------------------------------------------------------------------

    # Work::start()
    def self.start()
        KeyValueStore::set(nil, "0f4bd119-714d-442a-bf23-1e29b92e8c1b", Time.new.to_i)
    end

    # Work::stop()
    def self.stop()
        KeyValueStore::destroy(nil, "0f4bd119-714d-442a-bf23-1e29b92e8c1b")
    end

    # Work::getStartUnixtimeOrNull()
    def self.getStartUnixtimeOrNull()
        # This indicates whether the item is running or not
        unixtime = KeyValueStore::getOrNull(nil, "0f4bd119-714d-442a-bf23-1e29b92e8c1b")
        return nil if unixtime.nil?
        unixtime.to_f
    end

    # Work::isRunning()
    def self.isRunning()
        !Work::getStartUnixtimeOrNull().nil?
    end

    # Work::runningString()
    def self.runningString()
        return "" if !Work::isRunning()
        value = (Time.new.to_i - Work::getStartUnixtimeOrNull()).to_f/3600
        "(running for #{value.round(2)}) hours"
    end

    # ---------------------------------------------------------------------------

    # Work::isWorkTime()
    def self.isWorkTime()
        return false if Time.new.hour < 9
        return false if Time.new.hour >= 17
        [1,2,3,4,5].include?(Time.new.wday)
    end

    # Work::citcuitBreaker()
    def self.citcuitBreaker()
        b1 = Bank::valueOverTimespan("WORK-E4A9-4BCD-9824-1EEC4D648408", 3600*4) > 3600*3
        b2 = BankExtended::stdRecoveredDailyTimeInHours("WORK-E4A9-4BCD-9824-1EEC4D648408") > 7
        b1 or b2
    end

    # Work::shouldDisplayWork()
    def self.shouldDisplayWork()
        return true if Work::isRunning()
        return false if (KeyValueStore::getOrNull(nil, "ce621184-51d7-456a-8ad1-20e7d9acb350:#{Utils::today()}") == "ns:false")
        return false if !DoNotShowUntil::isVisible("WORK-E4A9-4BCD-9824-1EEC4D648408")
        return false if Work::citcuitBreaker()
        Work::isWorkTime()
    end

    # Work::formatPriorityFile(text)
    def self.formatPriorityFile(text)
        text.lines.first(5).map{|line| "        #{line}" }.join()
    end

    # ---------------------------------------------------------------------------

    # Work::priorityWorkFilepath()
    def self.priorityWorkFilepath()
        "/Users/pascal/Desktop/Priority Work.txt"
    end

    # Work::announce()
    def self.announce()
        uuid = "WORK-E4A9-4BCD-9824-1EEC4D648408"
        if Work::isRunning() then
            [
                "[#{"work".green}] (rt: #{"%4.2f" % BankExtended::stdRecoveredDailyTimeInHours(uuid)}) #{Work::runningString()} 👩🏻‍💻",
                "\n",
                Work::formatPriorityFile(IO.read(Work::priorityWorkFilepath())).green
            ].join()
        else
            "[work] (rt: #{"%4.2f" % BankExtended::stdRecoveredDailyTimeInHours(uuid)}) 👩🏻‍💻"
        end
    end

    # Work::ns16s()
    def self.ns16s()
        return [] if !Work::shouldDisplayWork()
        uuid = "WORK-E4A9-4BCD-9824-1EEC4D648408"
        [
            Nx50s::getOperationalNS16ByUUIDOrNull("20210525-161532-646669"), # Guardian Jedi
            {
                "uuid"     => uuid,
                "announce" => Work::announce(),
                "access"   => lambda { 
                    if !Work::isRunning() then
                        Work::start()
                    end
                },
                "done"     => lambda {
                    if Work::isRunning() then
                        timespan = [Time.new.to_i - Work::getStartUnixtimeOrNull(), 3600*2].min
                        puts "Adding #{timespan} seconds to Work ( WORK-E4A9-4BCD-9824-1EEC4D648408 )"
                        Bank::put("WORK-E4A9-4BCD-9824-1EEC4D648408", timespan)
                        Work::stop()
                    end
                },
                "[]"       => lambda {
                    if Work::isRunning() then
                        PriorityFile::applyNextTransformation(Work::priorityWorkFilepath())
                    end
                }
            }
        ].compact
    end
end


Thread.new {
    loop {
        sleep 120
        next if !Work::isRunning()
        if (Time.new.to_f - Work::getStartUnixtimeOrNull()) > 3600 then
            Utils::onScreenNotification("Catalyst", "[work] overrunning")
        end
    }
}
