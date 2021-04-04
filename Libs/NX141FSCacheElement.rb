
# encoding: UTF-8

class NX141FSCacheElement

    # --------------------------------------------------------------
    # Database

    # NX141FSCacheElement::setDescription(nx141, description)
    def self.setDescription(nx141, description)
        db = SQLite3::Database.new(Commons::nyxDatabaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _NX141Cache_ where _nx141_=?", [nx141]
        db.execute "insert into _NX141Cache_ (_unixtime_, _nx141_, _description_) values (?,?,?)", [Time.new.to_f, nx141, description]
        db.commit 
        db.close
    end

    # NX141FSCacheElement::getStoredDescriptionOrNull(nx141)
    def self.getStoredDescriptionOrNull(nx141)
        db = SQLite3::Database.new(Commons::nyxDatabaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute("select * from _NX141Cache_ where _nx141_=?", [nx141]) do |row|
            answer = row['_description_']
        end
        db.close
        answer
    end

    # NX141FSCacheElement::garbageCollection(horizon)
    def self.garbageCollection(horizon)
        db = SQLite3::Database.new(Commons::nyxDatabaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.execute "delete from _NX141Cache_ where _unixtime_<?", [horizon]
        db.close
    end

    # NX141FSCacheElement::getCacheItems()
    def self.getCacheItems()
        db = SQLite3::Database.new(Commons::nyxDatabaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _NX141Cache_") do |row|
            answer << {
                "nx141"       => row['_nx141_'],
                "description" => row['_description_']
            }
        end
        db.close
        answer
    end

    # NX141FSCacheElement::scan()
    def self.scan()
        GalaxyFinder::locationEnumerator(GalaxyFinder::rootScans()).each{|location|
            nx141 = NX141FilenameReaderWriter::extractNX141MarkerFromLocationOrNull(location)
            next if nx141.nil?
            puts location
            description = NX141FilenameReaderWriter::extractDescriptionFromLocation(location)
            NX141FSCacheElement::setDescription(nx141, description)
        }
    end

    # NX141FSCacheElement::destroy(element)
    def self.destroy(element)
        uuid = element["uuid"]
        db = SQLite3::Database.new(Commons::nyxDatabaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _NX141Cache_ where _nx141_=?", [uuid]
        db.commit 
        db.close
    end

    # --------------------------------------------------------------
    # Element

    # NX141FSCacheElement::toString(element)
    def self.toString(element)
        "[NX141] #{element["description"]}"
    end

    # NX141FSCacheElement::elements()
    def self.elements()
        NX141FSCacheElement::getCacheItems()
            .map{|item|
                nx141 = item["nx141"]
                description = item["description"]
                {
                    "uuid"           => nx141,
                    "nyxElementType" => "736ec8c8-daa6-48cf-8d28-84cfca79bedc",
                    "nx141"          => nx141,
                    "description"    => description || "" # items without a description come up with a null description
                }
            }
    end

    # NX141FSCacheElement::getElementByUUIDOrNull(uuid)
    def self.getElementByUUIDOrNull(uuid)
        NX141FSCacheElement::elements()
            .select{|element| element["uuid"] == uuid }
            .first
    end

    # NX141FSCacheElement::nyxSearchItems()
    def self.nyxSearchItems()
        NX141FSCacheElement::getCacheItems()
            .map{|item|
                volatileuuid = SecureRandom.hex[0, 8]
                element = NX141FSCacheElement::getElementByUUIDOrNull(item["nx141"])
                {
                    "announce"     => "#{volatileuuid} [NX141] #{item["description"]} | #{item["nx141"]}",
                    "payload"      => element
                }
            }
    end

    # NX141FSCacheElement::getElementsByIdentifier(identifier)
    def self.getElementsByIdentifier(identifier)
        NX141FSCacheElement::elements()
            .select{|element| (element["description"] == identifier) or element["nx141"] == identifier }
    end

    # NX141FSCacheElement::access(nx141)
    def self.access(nx141)
        location = GalaxyFinder::uniqueStringToLocationOrNull(nx141)
        if location.nil? then
            puts "-> I could not find the location for NX141 mark: #{nx141}"
            LucilleCore::pressEnterToContinue()
            return
        end
        if File.directory?(location) then
            system("open '#{location}'")
        else
            if location[-4, 4] == ".txt" then
                system("open '#{location}'")
                return
            end
            if location[-4, 4] == ".jpg" then
                system("open '#{location}'")
                return
            end
            if location[-4, 4] == ".png" then
                system("open '#{location}'")
                return
            end
            puts "[0f0a0154-c910-4e3a-a1b7-9d4d0e404197] I don't know how to open: '#{location}'"
            LucilleCore::pressEnterToContinue()
        end
    end

    # NX141FSCacheElement::landing(element)
    def self.landing(element)

        loop {
            system("clear")
            element = NX141FSCacheElement::getElementByUUIDOrNull(element["uuid"]) # could have been deleted or transmuted in the previous loop
            return if element.nil?

            puts NX141FSCacheElement::toString(element).green
            puts "uuid: #{element["uuid"]}".yellow

            puts ""

            if Patricia::isNX141FSCacheElement(element) then
                puts "location: #{GalaxyFinder::uniqueStringToLocationOrNull(element["nx141"])}".yellow
            end

            mx = LCoreMenuItemsNX1.new()

            location = GalaxyFinder::uniqueStringToLocationOrNull(element["nx141"])
            mx.item("real parent: #{File.dirname(location)}", lambda { 
                NX141FSCacheElement::landingOnFileSystemLocation(File.dirname(location))
            })

            if File.directory?(location) then
                location = GalaxyFinder::uniqueStringToLocationOrNull(element["nx141"])
                LucilleCore::locationsAtFolder(location)
                .select{|l| !File.basename(l).start_with?(".") }
                .each{|loc1|
                    mx.item("fs child: #{File.basename(loc1)}", lambda { 
                        NX141FSCacheElement::landingOnFileSystemLocation(loc1)
                    })
                }
            end

            Network::getLinkedObjects(element).each{|node|
                mx.item("related: #{Patricia::toString(node)}", lambda { 
                    Patricia::landing(node)
                })
            }

            puts ""

            mx.item("access".yellow, lambda { 
                NX141FSCacheElement::access(element["nx141"])
            })

            mx.item("link to network architected".yellow, lambda { 
                Patricia::linkToArchitectedNode(element)
            })

            mx.item("select and remove related".yellow, lambda {
                Patricia::selectAndRemoveLinkedNode(element)
            })

            mx.item("destroy".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("destroy ? : ") then
                    if Patricia::isNX141FSCacheElement(element) then
                        location = GalaxyFinder::uniqueStringToLocationOrNull(element["nx141"])
                        puts "This is a NX141FSCacheElement. You need to delete the file on disk (#{location})"
                        LucilleCore::pressEnterToContinue()
                        return if File.exists?(location)
                    end
                    NX141FSCacheElement::destroy(element)
                end
            })

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # NX141FSCacheElement::landingOnFileSystemLocation(location)
    def self.landingOnFileSystemLocation(location)
        # We first need to know if we have a NX141 location or nor
        marker = NX141FilenameReaderWriter::extractNX141MarkerFromLocationOrNull(location)
        if marker then
            uuid = marker
            element = NX141FSCacheElement::getElementByUUIDOrNull(uuid)
            NX141FSCacheElement::landing(element)
        else
            NX141FSCacheElement::landingOnNonNX141FileSystemLocation(location)
        end
    end

    # NX141FSCacheElement::landingOnNonNX141FileSystemLocation(location)
    def self.landingOnNonNX141FileSystemLocation(location)
        loop {
            system("clear")
            puts "location: #{location}"
            mx = LCoreMenuItemsNX1.new()

            mx.item("real parent: #{File.dirname(location)}", lambda { 
                NX141FSCacheElement::landingOnFileSystemLocation(File.dirname(location))
            })

            if File.file?(location) then
                mx.item("open access/location".yellow, lambda {
                    if File.directory?(location) then
                        system("open '#{location}'")
                    else
                        if location[-4, 4] == ".txt" then
                            system("open '#{location}'")
                            return
                        end
                        if location[-4, 4] == ".jpg" then
                            system("open '#{location}'")
                            return
                        end
                        if location[-4, 4] == ".png" then
                            system("open '#{location}'")
                            return
                        end
                        puts "[0f0a0154-c910-4e3a-a1b7-9d4d0e404197] I don't know how to open: '#{location}'"
                        LucilleCore::pressEnterToContinue()
                    end
                })
            end

            if File.directory?(location) then
                mx.item("patricia architect ; insert as child".yellow, lambda {
                    LucilleCore::locationsAtFolder(location)
                    .select{|l| !File.basename(l).start_with?(".") }
                    .each{|loc1|
                        mx.item("fs child : #{File.basename(loc1)}", lambda { 
                            NX141FSCacheElement::landingOnFileSystemLocation(loc1)
                        })
                    }
                })
            end

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end
end