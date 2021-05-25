# encoding: UTF-8

class DocNetTodo

    # DocNetTodo::uuid()
    def self.uuid()
        "e575a46c-ba58-4bc2-97f4-e047a2ee2123"
    end

    # DocNetTodo::applyNextTransformation(filepath, hash1)
    def self.applyNextTransformation(filepath, hash1)
        contents = IO.read(filepath)
        return if contents.strip == ""
        hash2 = Digest::SHA1.file(filepath).hexdigest
        return if hash1 != hash2
        contents = SectionsType0141::applyNextTransformationToText(contents)
        File.open(filepath, "w"){|f| f.puts(contents)}
    end

    # DocNetTodo::filepathToNS16OrNull(filepath)
    def self.filepathToNS16OrNull(filepath)

        raise "c2f47ddb-c278-4e03-b350-0a204040b224" if filepath.nil? # can happen because some of those filepath are unique string lookups
        filename = File.basename(filepath)
        return nil if IO.read(filepath).strip == ""

        uuid = DocNetTodo::uuid()

        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        dctime = ( Utils::isWeekday() and Time.new.hour >= 7 and Time.new.hour < 10 )
        level = dctime ? "ns:important" : "ns:zone"

        announce = "\n#{IO.read(filepath).strip.lines.first(10).map{|line| "      #{line}" }.join().green}"

        {
            "uuid"      => uuid,
            "metric"    => [level, rt, nil],
            "announce"  => announce,
            "access"    => lambda {

                startUnixtime = Time.new.to_f

                system("open '#{filepath}'")

                loop {
                    system("clear")

                    puts IO.read(filepath).strip.lines.first(10).join().strip.green
                    puts ""

                    puts "open | <datecode> | [] | (empty) # default # exit".yellow

                    command = LucilleCore::askQuestionAnswerAsString("> ")

                    break if command == ""

                    if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                        DoNotShowUntil::setUnixtime(uuid, unixtime)
                        break
                    end

                    if Interpreting::match("open", command) then
                        system("open '#{filepath}'")
                    end

                    if Interpreting::match("[]", command) then
                        Priority1::applyNextTransformation(filepath, Digest::SHA1.file(filepath).hexdigest)
                    end
                    
                    if Interpreting::match("", command) then
                        break
                    end
                }

                timespan = Time.new.to_f - startUnixtime

                puts "Time since start: #{timespan}"

                timespan = [timespan, 3600*2].min

                puts "putting #{timespan} seconds to uuid: #{uuid}"
                Bank::put(uuid, timespan)

                $counterx.registerTimeInSeconds(timespan)
            },
            "done"     => lambda { },
            "[]"       => lambda { Priority1::applyNextTransformation(filepath, Digest::SHA1.file(filepath).hexdigest) },
            "x-recovery-time" => BankExtended::stdRecoveredDailyTimeInHours(uuid)
        }
    end

    # DocNetTodo::ns16s()
    def self.ns16s()
        [ DocNetTodo::filepathToNS16OrNull(Utils::locationByUniqueStringOrNull("ab25a8f8-0578")) ].compact
    end
end