
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/CatalystFsck.rb"

require 'json'
# JSON.pretty_generate(object)

require 'time'
require 'date'
require 'colorize'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'find'
require 'thread'

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DoNotShowUntil.rb"
#    DoNotShowUntil::setUnixtime(uid, unixtime)
#    DoNotShowUntil::isVisible(uid)

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Common.rb"

# -----------------------------------------------------------------

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Waves/Waves.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Asteroids/Asteroids.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Cliques.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Cubes.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Quarks.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Librarian.rb"

# -------------------------------------------------------------------------

class CatalystFsck

    # CatalystFsck::entity(entity)
    def self.entity(entity)
        if entity["nyxNxSet"] == "4ebd0da9-6fe4-442e-81b9-eda8343fc1e5" then
            CatalystFsck::checkClique(entity)
            return
        end
        if entity["nyxType"] == "cube-933c2260-92d1-4578-9aaf-cd6557c664c6" then
            CatalystFsck::checkCube(entity)
            return
        end
        if entity["nyxNxSet"] == "6b240037-8f5f-4f52-841d-12106658171f" then
            CatalystFsck::checkQuark(entity)
            return
        end
        raise "-[ 85884767-b32a-4d8f-8399-4c31edac6eda ]-"
    end

    # CatalystFsck::checkWaves(wave)
    def self.checkWaves(wave)
        puts JSON.pretty_generate(wave)
        if wave["uuid"].nil? then
            puts "[error] wave has no uuid".red
            puts JSON.pretty_generate(wave).red
            exit
        end
        if wave["nyxType"].nil? then
            puts "[error] wave has no nyxType".red
            puts JSON.pretty_generate(wave).red
            exit
        end
        if wave["creationUnixtime"].nil? then
            puts "[error] wave has no creationUnixtime".red
            puts JSON.pretty_generate(wave).red
            exit
        end
        if wave["description"].nil? then
            puts "[error] wave has no description".red
            puts JSON.pretty_generate(wave).red
            exit
        end
        if wave["schedule"].nil? then
            puts "[error] wave has no schedule".red
            puts JSON.pretty_generate(wave).red
            exit
        end
        schedule = wave["schedule"]
    end

    # CatalystFsck::checkQuark(quark)
    def self.checkQuark(quark)
        puts JSON.pretty_generate(quark)

        if quark["uuid"].nil? then
            puts "[error] quark has no uuid".red
            puts JSON.pretty_generate(quark).red
            exit
        end

        if quark["nyxType"].nil? then
            puts "[error] quark has no nyxType".red
            puts JSON.pretty_generate(quark).red
            exit
        end

        if quark["nyxNxSet"] != "6b240037-8f5f-4f52-841d-12106658171f" then
            puts "[error] quark has incorrected nyxType".red
            puts JSON.pretty_generate(quark).red
            exit
        end

        if quark["creationUnixtime"].nil? then
            puts "[error] quark has no creationUnixtime".red
            puts JSON.pretty_generate(quark).red
            exit
        end

        # quark["description"]
        if quark["type"].nil? then
            puts "[error] quark has no type".red
            puts JSON.pretty_generate(quark).red
            exit
        end

        types = ["line", "url", "file", "folder", "unique-name"]
        if !types.include?(quark["type"]) then
            puts "[error] quark has incorrect type".red
            puts JSON.pretty_generate(quark).red
            exit
        end

        if quark["type"] == "line" then
            if quark["line"].nil? then
                puts "[error] quark has no line".red
                puts JSON.pretty_generate(quark).red
                exit
            end
        end

        if quark["type"] == "url" then
            if quark["url"].nil? then
                puts "[error] quark has no url".red
                puts JSON.pretty_generate(quark).red
                exit
            end
        end

        if quark["type"] == "file" then
            if quark["filename"].nil? then
                puts "[error] quark has no filename".red
                puts JSON.pretty_generate(quark).red
                exit
            end
            if !LibrarianFile::exists?(quark["filename"]) then
                puts "[error] Targetted file doesn't exists".red
                puts JSON.pretty_generate(quark).red
                exit
            end
        end

        if quark["type"] == "folder" then
            if quark["foldername"].nil? then
                puts "[error] quark has no foldername".red
                puts JSON.pretty_generate(quark).red
                exit
            end
            if !LibrarianDirectory::exists?(quark["foldername"]) then
                puts "[error] Targetted foldername doesn't exists".red
                puts JSON.pretty_generate(quark).red
                exit
            end
        end

        if quark["type"] == "unique-name" then
            if quark["name"].nil? then
                puts "[error] quark has no name".red
                puts JSON.pretty_generate(quark).red
                exit
            end
        end
    end

    # CatalystFsck::checkAsteroid(asteroid)
    def self.checkAsteroid(asteroid)
        puts JSON.pretty_generate(asteroid)
        if asteroid["uuid"].nil? then
            puts "[error] asteroid has no uuid".red
            puts JSON.pretty_generate(asteroid).red
            exit
        end
        if asteroid["nyxType"].nil? then
            puts "[error] asteroid has no nyxType".red
            puts JSON.pretty_generate(asteroid).red
            exit
        end
        if asteroid["nyxNxSet"] != "b66318f4-2662-4621-a991-a6b966fb4398" then
            puts "[error] asteroid has incorrect nyxType".red
            puts JSON.pretty_generate(asteroid).red
            exit
        end
        if asteroid["payload"].nil? then
            puts "[error] asteroid has no payload".red
            puts JSON.pretty_generate(asteroid).red
            exit
        end

        payloadTypes = ["description", "quark"]
        if !payloadTypes.include?(asteroid["payload"]["type"]) then
            puts "[error] asteroid has incorrect payload type".red
            puts JSON.pretty_generate(asteroid).red
            exit
        end

        if asteroid["payload"]["type"] == "quark" then
            quark = Quarks::getOrNull(asteroid["payload"]["quarkuuid"])
            if quark.nil? then
                puts "[error] Asteroid item has not known target quark".red
                puts JSON.pretty_generate(asteroid).red
                exit
            end
            CatalystFsck::checkQuark(quark)
        end

        if asteroid["orbital"].nil? then
            puts "[error] asteroid has no orbital".red
            puts JSON.pretty_generate(asteroid).red
            exit
        end

        orbitalTypes = [
            "singleton-time-commitment-7c67cb4f-77e0-4fd",
            "on-going-until-completion-5b26f145-7ebf-498",
            "indefinite-e79bb5c2-9046-4b86-8a79-eb7dc9e2",
            "repeating-daily-time-commitment-8123956c-05",
            "queued-8cb9c7bd-cb9a-42a5-8130-4c7c5463173c"
        ]
        if !orbitalTypes.include?(asteroid["orbital"]["type"]) then
            puts "[error] asteroid has incorrect orbital type".red
            puts JSON.pretty_generate(asteroid).red
            exit
        end
    end

    # CatalystFsck::checkClique(clique)
    def self.checkClique(clique)
        puts JSON.pretty_generate(clique)
        if clique["uuid"].nil? then
            puts "[error] clique has no uuid".red
            puts JSON.pretty_generate(clique).red
            exit
        end
        if clique["nyxType"].nil? then
            puts "[error] clique has no nyxType".red
            puts JSON.pretty_generate(clique).red
            exit
        end
        if clique["nyxNxSet"] != "4ebd0da9-6fe4-442e-81b9-eda8343fc1e5" then
            puts "[error] clique has incorrect nyxType".red
            puts JSON.pretty_generate(clique).red
            exit
        end
        if clique["name"].nil? then
            puts "[error] clique has no name".red
            puts JSON.pretty_generate(clique).red
            exit
        end
        if clique["name"].strip.size == 0 then
            puts "[error] clique has empty name".red
            puts JSON.pretty_generate(clique).red
            exit
        end
    end

    # CatalystFsck::checkCube(cube)
    def self.checkCube(cube)
        puts JSON.pretty_generate(cube)
        if cube["uuid"].nil? then
            puts "[error] starlight cube has no uuid".red
            puts JSON.pretty_generate(cube).red
            exit
        end
        if cube["nyxType"].nil? then
            puts "[error] starlight cube has no nyxType".red
            puts JSON.pretty_generate(cube).red
            exit
        end
        if cube["nyxType"] != "cube-933c2260-92d1-4578-9aaf-cd6557c664c6" then
            puts "[error] starlight cube has incorrect nyxType".red
            puts JSON.pretty_generate(cube).red
            exit
        end
    end

    # CatalystFsck::run()
    def self.run()
        Waves::waves().each{|wave|
            CatalystFsck::checkWaves(wave)
        }
        Asteroids::asteroids().each{|asteroid|
            CatalystFsck::checkAsteroid(asteroid)
        }
        Cliques::cliques().each{|clique|
            CatalystFsck::checkClique(clique)
        }
        puts "-> Completed Catalyst Integrity Check".green
    end
end
