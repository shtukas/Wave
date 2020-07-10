
# encoding: UTF-8

# require_relative "Drives.rb"

require_relative "ShadowFS.rb"

require_relative "KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require_relative "Miscellaneous.rb"

# -----------------------------------------------------------------

=begin
    {
        "drivename" : "EnergyGrid",
        "shadowFSPaths": [
            "/Volumes/EnergyGrid/Data/Pascal/DataPods"
        ]
    }
=end

class Drives
    # Drives::runShadowUpdate()
    def self.runShadowUpdate()
        drives = JSON.parse(IO.read("#{Miscellaneous::catalystDataCenterFolderpath()}/Drives/drives.json"))
        drives.each{|drive|
            drive["shadowFSPaths"].each{|shadowpath|
                if File.exists?(shadowpath) then
                    puts "shadowpath     : #{shadowpath}"
                    nhash = ShadowFS::commitLocationReturnHash(ShadowFSOperator.new(), shadowpath)
                    puts "nhash          : #{nhash}"
                    rootlocationkey = "2722ef66-6375-484d-8ee8-e0a4147d94aa:#{drive["drivename"]}:#{shadowpath}"
                    puts "rootlocationkey: #{rootlocationkey}"
                    KeyValueStore::set(nil, rootlocationkey, nhash)
                end
            }
        }
    end
end