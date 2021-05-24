# encoding: UTF-8

class AirTrafficControl

    # AirTrafficControl::defaultAgent()
    def self.defaultAgent()
        {
            "uuid" => "3AD70E36-826B-4958-95BF-02E12209C375",
            "name" => "quarks"
        }
    end

    # AirTrafficControl::agents()
    def self.agents()
        sas = LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataBank/Catalyst/AirTrafficControl")
                .select{|filepath| filepath[-5, 5] == ".json" }
                .map{|filepath| JSON.parse(IO.read(filepath)) }
        sas + [AirTrafficControl::defaultAgent()]
    end

    # AirTrafficControl::getAgentByIdOrNull(uuid)
    def self.getAgentByIdOrNull(uuid)
        AirTrafficControl::agents().select{|agent| agent["uuid"] == uuid }.first
    end

    # AirTrafficControl::commitAgentToDisk(agent)
    def self.commitAgentToDisk(agent)
        File.open("/Users/pascal/Galaxy/DataBank/Catalyst/AirTrafficControl/#{agent["uuid"]}.json", "w"){|f| f.puts(JSON.pretty_generate(agent))}
    end
end
