
# encoding: UTF-8

class GenericObjectInterface

    # GenericObjectInterface::isAsteroid(object)
    def self.isAsteroid(object)
        object["nyxNxSet"] == "b66318f4-2662-4621-a991-a6b966fb4398"
    end

    # GenericObjectInterface::isNode(object)
    def self.isNode(object)
        object["nyxNxSet"] == "c18e8093-63d6-4072-8827-14f238975d04"
    end

    # GenericObjectInterface::isDataline(object)
    def self.isDataline(object)
        object["nyxNxSet"] == "d319513e-1582-4c78-a4c4-bf3d72fb5b2d"
    end

    # GenericObjectInterface::isDataPoint(object)
    def self.isDataPoint(object)
        object["nyxNxSet"] == "0f555c97-3843-4dfe-80c8-714d837eba69"
    end

    # GenericObjectInterface::toString(object)
    def self.toString(object)
        if GenericObjectInterface::isAsteroid(object) then
            return Asteroids::toString(object)
        end
        if GenericObjectInterface::isNode(object) then
            return NSDataType1::toString(object)
        end
        if GenericObjectInterface::isDataline(object) then
            return NSDataLine::toString(object)
        end
        if GenericObjectInterface::isDataPoint(object) then
            return NSDataPoint::toString(object)
        end
        puts object
        raise "[error: d4c62cad-0080-4270-82a9-81b518c93c0e]"
    end

    # GenericObjectInterface::applyDateTimeOrderToObjects(objects)
    def self.applyDateTimeOrderToObjects(objects)
        objects
            .map{|object|
                {
                    "object"   => object,
                    "datetime" => GenericObjectInterface::getObjectReferenceDateTime(object)
                }
            }
            .sort{|i1, i2|
                i1["datetime"] <=> i2["datetime"]
            }
            .map{|i| i["object"] }
    end

    # GenericObjectInterface::getObjectReferenceDateTime(object)
    def self.getObjectReferenceDateTime(object)
        datetime = NSDataTypeXExtended::getLastDateTimeForTargetOrNull(object)
        return datetime if datetime
        Time.at(object["unixtime"]).utc.iso8601
    end

    # GenericObjectInterface::landing(object)
    def self.landing(object)
        if GenericObjectInterface::isAsteroid(object) then
            Asteroids::landing(object)
            return
        end
        if GenericObjectInterface::isNode(object) then
            NSDataType1::landing(object)
            return
        end
        if GenericObjectInterface::isDataline(object) then
            NSDataLine::landing(object)
            return
        end
        if GenericObjectInterface::isDataPoint(object) then
            loop {
                system("clear")
                puts NSDataPoint::toString(object)
                mode = LucilleCore::selectEntityFromListOfEntitiesOrNull("mode", ["enter", "destroy"])
                break if mode.nil?
                if mode == "enter" then
                    NSDataPoint::enterDataPoint(object)
                    next
                end
                if mode == "destroy" then
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to do that? : ") then
                        GenericObjectInterface::destroy(object)
                        return
                    end
                end
            }
            return
        end


    end

    # GenericObjectInterface::destroy(object)
    def self.destroy(object)
        if GenericObjectInterface::isAsteroid(object) then
            return
        end
        if GenericObjectInterface::isNode(object) then
            NSDataType1::destroy(object)
            return
        end
        if GenericObjectInterface::isDataline(object) then
            NyxObjects2::destroy(object)
            return
        end
        if GenericObjectInterface::isDataPoint(object) then
            NyxObjects2::destroy(object)
            return
        end
        puts object
        raise "[error: 09e17b29-8620-4345-b358-89c58c248d6f]"
    end
end