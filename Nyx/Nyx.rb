
# encoding: UTF-8

require 'json'
# JSON.pretty_generate(object)

require 'date'
require 'colorize'
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'time'

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
require 'drb/drb'
require 'thread'

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/YmirEstate.rb"
=begin
    YmirEstate::ymirFilepathEnumerator(pathToYmir)
    YmirEstate::locationBasenameToYmirLocationOrNull(pathToYmir, basename)
    YmirEstate::makeNewYmirLocationForBasename(pathToYmir, basename)
        # If base name is meant to be the name of a folder then folder itself 
        # still need to be created. Only the parent is created.
=end

# --------------------------------------------------------------------

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Nyx.rb"

class NyxCuration

    # NyxCuration::curate()
    def self.curate()

        # ----------------------------------------------------------------------------------------
        # Remove permanodes with no targets
        NyxPermanodeOperator::permanodesEnumerator(Nyx::pathToYmir())
            .select{|permanode| permanode["targets"].size == 0 }
            .each{|permanode|
                puts "Destroying permanode '#{permanode["description"]}' (no targets)"
                NyxPermanodeOperator::destroyPermanodeAttempt(permanode)
            }

        # ----------------------------------------------------------------------------------------
        # Correct permanodes with descriptions with have more than one lines
        NyxPermanodeOperator::permanodesEnumerator(Nyx::pathToYmir())
            .select{|permanode|
                permanode["description"].lines.to_a.size > 1
            }
            .each{|permanode|
                puts "Correcting permanode description"
                permanode["description"] = NyxMiscUtils::editTextUsingTextmate(permanode["description"]).strip
                NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
            }

    end
end

class NyxMiscUtils

    # NyxMiscUtils::editTextUsingTextmate(text)
    def self.editTextUsingTextmate(text)
      filename = SecureRandom.hex
      filepath = "/tmp/#{filename}"
      File.open(filepath, 'w') {|f| f.write(text)}
      system("/usr/local/bin/mate \"#{filepath}\"")
      print "> press enter when done: "
      input = STDIN.gets
      IO.read(filepath)
    end

    # NyxMiscUtils::l22()
    def self.l22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # NyxMiscUtils::chooseALinePecoStyle(announce: String, strs: Array[String]): String
    def self.chooseALinePecoStyle(announce, strs)
        `echo "#{strs.join("\n")}" | peco --prompt "#{announce}"`.strip
    end

    # NyxMiscUtils::cleanStringToBeFileSystemName(str)
    def self.cleanStringToBeFileSystemName(str)
        str = str.gsub(" ", "-")
        str = str.gsub("'", "-")
        str = str.gsub(":", "-")
        str = str.gsub("/", "-")
        str = str.gsub("!", "-")
        str
    end

    # NyxMiscUtils::locationsNamesInsideFolder(folderpath): Array[String]
    def self.locationsNamesInsideFolder(folderpath)
        Dir.entries(folderpath)
            .reject{|filename| [".", ".."].include?(filename) }
            .reject{|filename| filename == "Icon\r" }
            .reject{|filename| filename == ".DS_Store" }
            .sort
    end

    # NyxMiscUtils::locationPathsInsideFolder(folderpath): Array[String]
    def self.locationPathsInsideFolder(folderpath)
        NyxMiscUtils::locationsNamesInsideFolder(folderpath).map{|filename| "#{folderpath}/#{filename}" }
    end

    # NyxMiscUtils::readFileAsIndividualNonEmptyStrippedLineItems(filepath)
    def self.readFileAsIndividualNonEmptyStrippedLineItems(filepath)
        IO.read(filepath).lines.map{|line| line.strip }.select{|line| line.size > 0 }
    end

    # NyxMiscUtils::recursivelyComputedLocationTrace(location): String
    def self.recursivelyComputedLocationTrace(location)
        if File.file?(location) then
            Digest::SHA1.hexdigest("#{location}:#{File.mtime(location)}")
        else
            Digest::SHA1.hexdigest(
                ([location] + NyxMiscUtils::locationPathsInsideFolder(location).map{|l| NyxMiscUtils::recursivelyComputedLocationTrace(l) }).join("::")
            )
        end
    end

    # NyxMiscUtils::rsync(sourceFolderpath, targetFolderpath)
    def self.rsync(sourceFolderpath, targetFolderpath)
        if !File.exists?(sourceFolderpath) then
            raise "[error: 653b1b57] Impossible rsync" 
        end
        command = "rsync --xattrs --times --recursive --hard-links --delete --delete-excluded --verbose --human-readable --itemize-changes --links '#{sourceFolderpath}/' '#{targetFolderpath}'"
        system(command)
    end

    # NyxMiscUtils::uniqueNameResolutionLocationPathOrNull(uniquename)
    def self.uniqueNameResolutionLocationPathOrNull(uniquename)
        location = AtlasCore::uniqueStringToLocationOrNull(uniquename)
        return nil if location.nil?
        location
    end

    # NyxMiscUtils::lStoreMarkResolutionToMarkFilepathOrNull(mark)
    def self.lStoreMarkResolutionToMarkFilepathOrNull(mark)
        location = AtlasCore::uniqueStringToLocationOrNull(mark)
        return nil if location.nil?
        location
    end

    # NyxMiscUtils::isProperDateTimeIso8601(datetime)
    def self.isProperDateTimeIso8601(datetime)
        DateTime.parse(datetime).to_time.utc.iso8601 == datetime
    end

    # NyxMiscUtils::publishIndex2PermanodesAsOneObject()
    def self.publishIndex2PermanodesAsOneObject()
        targetFilepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Nyx/permanodes.json"
        File.open(targetFilepath, "w"){|f| f.puts(JSON.pretty_generate(NyxPermanodeOperator::permanodesEnumerator(Nyx::pathToYmir()).to_a))}
    end

    # NyxMiscUtils::formatTimeline(timeline)
    def self.formatTimeline(timeline)
        timeline.split(" ").map{|word| word.downcase.capitalize }.join(" ")
    end

    # NyxMiscUtils::selectOneFilepathOnTheDesktopOrNull()
    def self.selectOneFilepathOnTheDesktopOrNull()
        desktopLocations = LucilleCore::locationsAtFolder("/Users/pascal/Desktop")
                            .select{|filepath| filepath[0,1] != '.' }
                            .sort
        LucilleCore::selectEntityFromListOfEntitiesOrNull("location", desktopLocations, lambda{ |location| File.basename(location) })
    end

    # NyxMiscUtils::selectOneOrMoreFilesOnTheDesktopByLocation()
    def self.selectOneOrMoreFilesOnTheDesktopByLocation() # Array[String]
        desktopLocations = LucilleCore::locationsAtFolder("/Users/pascal/Desktop")
                            .select{|filepath| filepath[0,1]!='.' }
                            .sort
        puts "Select files:"
        locations, _ = LucilleCore::selectZeroOrMore("files:", [], desktopLocations, lambda{ |location| File.basename(location) })
        locations
    end

    # NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
    def self.commitPermanodeToDiskWithMaintenance(permanode)
        NyxPermanodeOperator::commitPermanodeToDisk(Nyx::pathToYmir(), permanode)
        NyxMiscUtils::publishIndex2PermanodesAsOneObject()
    end

    # NyxMiscUtils::levenshteinDistance(s, t)
    def self.levenshteinDistance(s, t)
      # https://stackoverflow.com/questions/16323571/measure-the-distance-between-two-strings-with-ruby
      m = s.length
      n = t.length
      return m if n == 0
      return n if m == 0
      d = Array.new(m+1) {Array.new(n+1)}

      (0..m).each {|i| d[i][0] = i}
      (0..n).each {|j| d[0][j] = j}
      (1..n).each do |j|
        (1..m).each do |i|
          d[i][j] = if s[i-1] == t[j-1]  # adjust index into string
                      d[i-1][j-1]       # no operation required
                    else
                      [ d[i-1][j]+1,    # deletion
                        d[i][j-1]+1,    # insertion
                        d[i-1][j-1]+1,  # substitution
                      ].min
                    end
        end
      end
      d[m][n]
    end

    # NyxMiscUtils::nyxStringDistance(str1, str2)
    def self.nyxStringDistance(str1, str2)
        # This metric takes values between 0 and 1
        return 1 if str1.size == 0
        return 1 if str2.size == 0
        NyxMiscUtils::levenshteinDistance(str1, str2).to_f/[str1.size, str2.size].max
    end

end

class NyxPermanodeOperator

    # ------------------------------------------
    # Integrity

    # NyxPermanodeOperator::objectIsPermanodeTarget(object)
    def self.objectIsPermanodeTarget(object)
        return false if object.nil?
        return false if object["uuid"].nil?
        return false if object["type"].nil?
        types = [
            "url-EFB8D55B",
            "file-3C93365A",
            "unique-name-C2BF46D6",
            "lstore-directory-mark-BEE670D0",
            "perma-dir-11859659"
        ]
        return false if !types.include?(object["type"])
        if object["type"] == "perma-dir-11859659" then
            return false if object["foldername"].nil?
        end
        true
    end

    # Return true if the passed object is a well formed permanode
    # NyxPermanodeOperator::objectIsPermanode(object)
    def self.objectIsPermanode(object)
        return false if object.nil?
        return false if object["uuid"].nil?
        return false if object["filename"].nil?
        return false if object["referenceDateTime"].nil?
        return false if DateTime.parse(object["referenceDateTime"]).to_time.utc.iso8601 != object["referenceDateTime"]
        return false if object["description"].nil?
        return false if object["description"].lines.to_a.size != 1
        return false if object["targets"].nil?
        return false if object["targets"].any?{|target| !NyxPermanodeOperator::objectIsPermanodeTarget(target) }
        return false if object["classification"].nil?
        true
    end

    # ------------------------------------------------------------------
    # To Strings

    # NyxPermanodeOperator::permanodeTargetToString(target)
    def self.permanodeTargetToString(target)
        if target["type"] == "url-EFB8D55B" then
            return "url       : #{target["url"]}"
        end
        if target["type"] == "file-3C93365A" then
            return "file      : #{target["filename"]}"
        end
        if target["type"] == "unique-name-C2BF46D6" then
            return "uniquename: #{target["name"]}"
        end
        if target["type"] == "lstore-directory-mark-BEE670D0" then
            return "mark      : #{target["mark"]}"
        end
        if target["type"] == "perma-dir-11859659" then
            return "PermaDir  : #{target["uuid"]}"
        end
        raise "[error: f84bb73d]"
    end

    # NyxPermanodeOperator::permanodeClassificationToString(item)
    def self.permanodeClassificationToString(item)
        if item["type"] == "tag-18303A17" then
            return "tag       : #{item["tag"]}"
        end
        if item["type"] == "timeline-329D3ABD" then
            return "timeline  : #{item["timeline"]}"
        end
        raise "[error: 071e4925]"
    end

    # ------------------------------------------
    # Opening

    # NyxPermanodeOperator::fileCanBeSafelyOpen(filename)
    def self.fileCanBeSafelyOpen(filename)
        true # TODO
    end

    # NyxPermanodeOperator::openPermanodeTarget(pathToYmir, target)
    def self.openPermanodeTarget(pathToYmir, target)
        if target["type"] == "url-EFB8D55B" then
            url = target["url"]
            system("open '#{url}'")
            return
        end
        if target["type"] == "file-3C93365A" then
            filename = target["filename"]
            filepath = YmirEstate::locationBasenameToYmirLocationOrNull(pathToYmir, filename)
            if NyxPermanodeOperator::fileCanBeSafelyOpen(filename) then
                system("open '#{filepath}'")
            else
                puts "Copying file to Desktop: #{File.basename(filepath)}"
                File.cp(filepath, "/Users/pascal/Desktop/#{File.basename(filepath)}")
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        if target["type"] == "unique-name-C2BF46D6" then
            uniquename = target["name"]
            location = NyxMiscUtils::uniqueNameResolutionLocationPathOrNull(uniquename)
            if location then
                puts "opening: #{location}"
                system("open '#{location}'")
            else
                puts "I could not determine the location of unique name: #{uniquename}"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        if target["type"] == "lstore-directory-mark-BEE670D0" then
            location = NyxMiscUtils::lStoreMarkResolutionToMarkFilepathOrNull(target["mark"])
            if location then
                puts "opening: #{File.dirname(location)}"
                system("open '#{File.dirname(location)}'")
            else
                puts "I could not determine the location of mark: #{target["mark"]}"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        if target["type"] == "perma-dir-11859659" then
            folderpath = YmirEstate::locationBasenameToYmirLocationOrNull(pathToYmir, target["foldername"])
            if folderpath.nil? then
                puts "[error: dbd35b00] This should not have happened. Cannot find folder for permadir foldername '#{target["foldername"]}'"
                LucilleCore::pressEnterToContinue()
                return
            end
            system("open '#{folderpath}'")
            return
        end
        raise "[error: 15c46fdd]"
    end

    # ------------------------------------------
    # IO Ops

    # NyxPermanodeOperator::makePermanodeFilename()
    def self.makePermanodeFilename()
        "#{NyxMiscUtils::l22()}.json"
    end

    # NyxPermanodeOperator::permanodeFilenameToFilepathOrNull(pathToYmir, filename)
    def self.permanodeFilenameToFilepathOrNull(pathToYmir, filename)
        YmirEstate::ymirFilepathEnumerator(pathToYmir).each{|filepath|
            return filepath if ( File.basename(filepath) == filename )
        }
        nil
    end

    # NyxPermanodeOperator::destroyPermanode(pathToYmir, permanode)
    def self.destroyPermanode(pathToYmir, permanode)
        filepath = NyxPermanodeOperator::permanodeFilenameToFilepathOrNull(pathToYmir, permanode["filename"])
        puts filepath
        return if filepath.nil?
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # NyxPermanodeOperator::commitPermanodeToDisk(pathToYmir, permanode)
    def self.commitPermanodeToDisk(pathToYmir, permanode)
        raise "[error: not a permanode]" if !NyxPermanodeOperator::objectIsPermanode(permanode)
        filepath = NyxPermanodeOperator::permanodeFilenameToFilepathOrNull(pathToYmir, permanode["filename"])
        if filepath.nil? then
            # probably a new permanode 
            filepath = YmirEstate::makeNewYmirLocationForBasename(pathToYmir, permanode["filename"])
        end
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(permanode)) }
    end

    # NyxPermanodeOperator::getPermanodeByUUIDOrNull(pathToYmir, permanodeuuid)
    def self.getPermanodeByUUIDOrNull(pathToYmir, permanodeuuid)
        NyxPermanodeOperator::permanodesEnumerator(pathToYmir).each{|permanode|
            return permanode if ( permanode["uuid"] == permanodeuuid )
        }
        nil
    end

    # NyxPermanodeOperator::permanodesEnumerator(pathToYmir)
    def self.permanodesEnumerator(pathToYmir)
        isFilenameOfPermanode = lambda {|filename|
            filename[-5, 5] == ".json"
        }
        Enumerator.new do |permanodes|
            YmirEstate::ymirFilepathEnumerator(pathToYmir).each{|filepath|
                next if !isFilenameOfPermanode.call(File.basename(filepath))
                permanodes << JSON.parse(IO.read(filepath))
            }
        end
    end

    # ------------------------------------------------------------------
    # To Strings

    # NyxPermanodeOperator::printPermanodeDetails(permanode)
    def self.printPermanodeDetails(permanode)
        puts "Permanode:"
        puts "    uuid: #{permanode["uuid"]}"
        puts "    filename: #{permanode["filename"]}"
        puts "    description: #{permanode["description"]}"
        puts "    datetime: #{permanode["referenceDateTime"]}"
        puts "    targets:"
        permanode["targets"].each{|permanodeTarget|
            puts "        #{NyxPermanodeOperator::permanodeTargetToString(permanodeTarget)}"
        }
        if permanode["classification"].empty? then
            puts "    classification: (empty set)"
        else
            puts "    classification"
            permanode["classification"].each{|item|
                puts "        #{NyxPermanodeOperator::permanodeClassificationToString(item)}"
            }
        end
    end

    # ------------------------------------------------------------------
    # Data Queries and Data Manipulations

    # NyxPermanodeOperator::timelines()
    def self.timelines()
        NyxPermanodeOperator::permanodesEnumerator(Nyx::pathToYmir())
            .reduce([]){|timelines, permanode|
                timelines + permanode["classification"].select{|permanodeTarget| permanodeTarget["type"] == "timeline-329D3ABD" }.map{|permanodeTarget| permanodeTarget["timeline"] }
            }
    end

    # NyxPermanodeOperator::timelinesInDecreasingActivityDateTime()
    def self.timelinesInDecreasingActivityDateTime()
        # struct1: Map[Timeline, DateTime]
        struct1 = NyxPermanodeOperator::permanodesEnumerator(Nyx::pathToYmir())
            .reduce({}){|datedTimelines, permanode|
                referenceDateTime = permanode["referenceDateTime"]
                timelines = permanode["classification"]
                                .select{|permanodeTarget| permanodeTarget["type"] == "timeline-329D3ABD" }
                                .map{|permanodeTarget| permanodeTarget["timeline"] }
                timelines.each{|timeline|
                    if datedTimelines[timeline].nil? then
                        datedTimelines[timeline] = referenceDateTime
                    else
                        datedTimelines[timeline] = [datedTimelines[timeline], referenceDateTime].max
                    end
                }
                datedTimelines
            }
            .map{|timeline, datetime| [timeline, datetime] }
            .sort{|p1, p2| p1[1]<=>p2[1] }
            .map{|i| i[0] }
            .reverse
    end

    # NyxPermanodeOperator::applyReferenceDateTimeOrderToPermanodes(permanodes)
    def self.applyReferenceDateTimeOrderToPermanodes(permanodes)
        permanodes.sort{|p1, p2| p1["referenceDateTime"] <=> p2["referenceDateTime"] }
    end

    # NyxPermanodeOperator::getTimelinePermanodes(timeline)
    def self.getTimelinePermanodes(timeline)
        NyxPermanodeOperator::permanodesEnumerator(Nyx::pathToYmir())
            .select{|permanode| permanode["classification"].any?{|item| item["type"] == "timeline-329D3ABD" and item["timeline"] == timeline}}
    end

    # NyxPermanodeOperator::getPermanodesCarryingThisDirectoryMark(mark)
    def self.getPermanodesCarryingThisDirectoryMark(mark)
        NyxPermanodeOperator::permanodesEnumerator(Nyx::pathToYmir())
            .select{|permanode|
                permanode["targets"].any?{|target| target["type"] == "lstore-directory-mark-BEE670D0" and target["mark"] == mark }
            }
    end

    # ------------------------------------------------------------------
    # Interactive Makers

    # NyxPermanodeOperator::makePermanodeTargetFileInteractiveOrNull()
    def self.makePermanodeTargetFileInteractiveOrNull()
        filepath1 = NyxMiscUtils::selectOneFilepathOnTheDesktopOrNull()
        return nil if filepath1.nil?
        filename1 = File.basename(filepath1)
        filename2 = "#{NyxMiscUtils::l22()}-#{filename1}"
        filepath2 = "#{File.dirname(filepath1)}/#{filename2}"
        FileUtils.mv(filepath1, filepath2)
        filepath3 = YmirEstate::makeNewYmirLocationForBasename(Nyx::pathToYmir(), filename2)
        FileUtils.mv(filepath2, filepath3)
        return {
            "uuid"     => SecureRandom.uuid,
            "type"     => "file-3C93365A",
            "filename" => filename2
        }
    end

    # NyxPermanodeOperator::makePermanodeTargetLStoreDirectoryMarkInteractiveOrNull()
    def self.makePermanodeTargetLStoreDirectoryMarkInteractiveOrNull()
        options = ["mark file already exists", "mark file should be created"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
        return nil if option.nil?
        if option == "mark file already exists" then
            mark = LucilleCore::askQuestionAnswerAsString("mark: ")
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "lstore-directory-mark-BEE670D0",
                "mark" => mark
            }
        end
        if option == "mark file should be created" then
            mark = nil
            loop {
                targetFolderLocation = LucilleCore::askQuestionAnswerAsString("Location to the target folder: ")
                if !File.exists?(targetFolderLocation) then
                    puts "I can't see location '#{targetFolderLocation}'"
                    puts "Let's try that again..."
                    next
                end
                mark = SecureRandom.uuid
                markFilepath = "#{targetFolderLocation}/Nyx-Directory-Mark.txt"
                File.open(markFilepath, "w"){|f| f.write(mark) }
                break
            }
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "lstore-directory-mark-BEE670D0",
                "mark" => mark
            }
        end
    end

    # NyxPermanodeOperator::selectOneExistingTimelineOrNull()
    def self.selectOneExistingTimelineOrNull()
        timeline = NyxMiscUtils::chooseALinePecoStyle("Timeline", [""] + NyxPermanodeOperator::timelinesInDecreasingActivityDateTime())
        return nil if timeline.size == 0
        timeline
    end

    # NyxPermanodeOperator::makeZeroOrMoreClassificationItemsTags()
    def self.makeZeroOrMoreClassificationItemsTags()
        items = []
        loop {
            tag = LucilleCore::askQuestionAnswerAsString("tag (empty for exit): ")
            break if tag.size == 0
            item = {
                "uuid" => SecureRandom.uuid,
                "type" => "tag-18303A17",
                "tag"  => tag
            }
            items << item
        }
        items
    end

    # NyxPermanodeOperator::makeZeroOrMoreClassificationItemsInteractive()
    def self.makeZeroOrMoreClassificationItemsInteractive()
        puts "-> specifiying classification: (1) tags, (2) timeline among existing, (3) new timelines"
        objects = []
        NyxPermanodeOperator::makeZeroOrMoreClassificationItemsTags()
            .each{|item| objects << item }
        loop {
            timeline = NyxPermanodeOperator::selectOneExistingTimelineOrNull()
            break if timeline.nil?
            object = {
                "uuid" => SecureRandom.uuid,
                "type" => "timeline-329D3ABD",
                "timeline"  => timeline
            }
            objects << object
        }
        loop {
            timeline = LucilleCore::askQuestionAnswerAsString("timeline (empty for exit): ")
            break if timeline.size == 0
            object = {
                "uuid" => SecureRandom.uuid,
                "type" => "timeline-329D3ABD",
                "timeline"  => NyxMiscUtils::formatTimeline(timeline)
            }
            objects << object
        }
        objects
    end

    # NyxPermanodeOperator::makePermanodeTargetInteractiveOrNull(type)
    # type = nil | "url-EFB8D55B" | "file-3C93365A" | "unique-name-C2BF46D6" | "lstore-directory-mark-BEE670D0" | "perma-dir-11859659"
    def self.makePermanodeTargetInteractiveOrNull(type)
        permanodeTargetType =
            if type.nil? then
                LucilleCore::selectEntityFromListOfEntitiesOrNull("type", [
                    "url-EFB8D55B",
                    "unique-name-C2BF46D6",
                    "file-3C93365A",
                    "lstore-directory-mark-BEE670D0",
                    "perma-dir-11859659"]
                )
            else
                type
            end
        return nil if permanodeTargetType.nil?
        if permanodeTargetType == "url-EFB8D55B" then
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "url-EFB8D55B",
                "url"  => LucilleCore::askQuestionAnswerAsString("url: ").strip
            }
        end
        if permanodeTargetType == "file-3C93365A" then
            return NyxPermanodeOperator::makePermanodeTargetFileInteractiveOrNull()
        end
        if permanodeTargetType == "unique-name-C2BF46D6" then
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "unique-name-C2BF46D6",
                "name" => LucilleCore::askQuestionAnswerAsString("uniquename: ").strip
            }
        end
        if permanodeTargetType == "lstore-directory-mark-BEE670D0" then
            return NyxPermanodeOperator::makePermanodeTargetLStoreDirectoryMarkInteractiveOrNull()
        end
        if permanodeTargetType == "perma-dir-11859659" then
            foldername1 = LucilleCore::askQuestionAnswerAsString("Desktop foldername: ")
            folderpath1 = "/Users/pascal/Desktop/#{foldername1}"
            foldername2 = NyxMiscUtils::l22()
            folderpath2 = YmirEstate::makeNewYmirLocationForBasename(Nyx::pathToYmir(), foldername2)
            FileUtils.mkdir(folderpath2)
            puts "Migrating '#{folderpath1}' to '#{folderpath2}'"
            LucilleCore::migrateContents(folderpath1, folderpath2)
            puts "'#{folderpath1}' has been emptied"
            LucilleCore::pressEnterToContinue()
            return {
                "uuid"       => SecureRandom.uuid,
                "type"       => "perma-dir-11859659",
                "foldername" => foldername2
            }
        end
        nil
    end

    # NyxPermanodeOperator::makePermanode2Interactive(description, permanodeTarget)
    def self.makePermanode2Interactive(description, permanodeTarget)
        permanode = {}
        permanode["uuid"] = SecureRandom.uuid
        permanode["filename"] = NyxPermanodeOperator::makePermanodeFilename()
        permanode["creationTimestamp"] = Time.new.to_f
        permanode["referenceDateTime"] = Time.now.utc.iso8601
        permanode["description"] = description
        permanode["targets"] = [ permanodeTarget ]
        permanode["classification"] = NyxPermanodeOperator::makeZeroOrMoreClassificationItemsInteractive()
        permanode
    end

    # NyxPermanodeOperator::makePermanodeInteractive()
    def self.makePermanodeInteractive()
        operations = [
            "url",
            "uniquename",
            "file (from desktop)",
            "lstore-directory-mark",
            "Desktop files inside permadir"
        ]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)

        if operation == "url" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            permanodeTarget = {
                "uuid" => SecureRandom.uuid,
                "type" => "url-EFB8D55B",
                "url" => url
            }
            permanode = NyxPermanodeOperator::makePermanode2Interactive(description, permanodeTarget)
            puts JSON.pretty_generate(permanode)
            NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
        end

        if operation == "uniquename" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            uniquename = LucilleCore::askQuestionAnswerAsString("unique name: ")
            permanodeTarget = {
                "uuid" => SecureRandom.uuid,
                "type" => "unique-name-C2BF46D6",
                "name" => uniquename
            }
            permanode = NyxPermanodeOperator::makePermanode2Interactive(description, permanodeTarget)
            puts JSON.pretty_generate(permanode)
            NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
        end

        if operation == "file (from desktop)" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            permanodeTarget = NyxPermanodeOperator::makePermanodeTargetFileInteractiveOrNull()
            return if permanodeTarget.nil?
            permanode = NyxPermanodeOperator::makePermanode2Interactive(description, permanodeTarget)
            puts JSON.pretty_generate(permanode)
            NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
        end

        if operation == "lstore-directory-mark" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            permanodeTarget = NyxPermanodeOperator::makePermanodeTargetLStoreDirectoryMarkInteractiveOrNull()
            return if permanodeTarget.nil?
            permanode = NyxPermanodeOperator::makePermanode2Interactive(description, permanodeTarget)
            puts JSON.pretty_generate(permanode)
            NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
        end

        if operation == "Desktop files inside permadir" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            locations = NyxMiscUtils::selectOneOrMoreFilesOnTheDesktopByLocation()

            foldername2 = NyxMiscUtils::l22()
            folderpath2 = YmirEstate::makeNewYmirLocationForBasename(Nyx::pathToYmir(), foldername2)
            FileUtils.mkdir(folderpath2)

            permanodeTarget = {
                "uuid"       => SecureRandom.uuid,
                "type"       => "perma-dir-11859659",
                "foldername" => foldername2
            }
            permanode = NyxPermanodeOperator::makePermanode2Interactive(description, permanodeTarget)
            puts JSON.pretty_generate(permanode)
            NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)

            locations.each{|location|
                puts "Copying '#{location}'"
                LucilleCore::copyFileSystemLocation(location, folderpath2)
            }
            locations.each{|location|
                LucilleCore::removeFileSystemLocation(location)
            }
            system("open '#{folderpath2}'")
        end
    end

    # ------------------------------------------------------------------
    # Dives

    # NyxPermanodeOperator::permanodeTargetDive(permanodeuuid, permanodeTarget)
    def self.permanodeTargetDive(permanodeuuid, permanodeTarget)
        puts "-> permanodeTarget:"
        puts JSON.pretty_generate(permanodeTarget)
        puts NyxPermanodeOperator::permanodeTargetToString(permanodeTarget)
        NyxPermanodeOperator::openPermanodeTarget(Nyx::pathToYmir(), permanodeTarget)
    end

    # NyxPermanodeOperator::permanodeTargetsDive(permanode)
    def self.permanodeTargetsDive(permanode)
        toStringLambda = lambda { |permanodeTarget| NyxPermanodeOperator::permanodeTargetToString(permanodeTarget) }
        permanodeTarget = LucilleCore::selectEntityFromListOfEntitiesOrNull("Choose target", permanode["targets"], toStringLambda)
        return if permanodeTarget.nil?
        NyxPermanodeOperator::permanodeTargetDive(permanode["uuid"], permanodeTarget)
    end

    # NyxPermanodeOperator::permanodeDive(permanode)
    def self.permanodeDive(permanode)
        loop {
            NyxPermanodeOperator::printPermanodeDetails(permanode)
            operations = [
                "quick open",
                "edit description",
                "edit reference datetime",
                "targets dive",
                "targets (add new)",
                "targets (select and remove)",
                "tag (add new)",
                "timeline (add new as string)",
                "timeline (add new select from existing)",
                "classification (select and remove)",
                "edit permanode.json",
                "destroy permanode"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "quick open" then
                NyxPermanodeOperator::permanodeOptimisticOpen(permanode)
            end
            if operation == "edit description" then
                permanode = NyxPermanodeOperator::getPermanodeByUUIDOrNull(Nyx::pathToYmir(), permanode["uuid"])
                newdescription = NyxMiscUtils::editTextUsingTextmate(permanode["description"]).strip
                if newdescription == "" or newdescription.lines.to_a.size != 1 then
                    puts "Descriptions should have one non empty line"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                permanode["description"] = newdescription
                NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
            end
            if operation == "edit reference datetime" then
                permanode = NyxPermanodeOperator::getPermanodeByUUIDOrNull(Nyx::pathToYmir(), permanode["uuid"])
                referenceDateTime = NyxMiscUtils::editTextUsingTextmate(permanode["referenceDateTime"]).strip
                if NyxMiscUtils::isProperDateTimeIso8601(referenceDateTime) then
                    permanode["referenceDateTime"] = referenceDateTime
                    NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
                else
                    puts "I could not validate #{referenceDateTime} as a proper iso8601 datetime"
                    puts "Aborting operation"
                    LucilleCore::pressEnterToContinue()
                end
            end
            if operation == "target dive" then
                NyxPermanodeOperator::permanodeTargetDive(permanode["uuid"], permanode["targets"].first)
            end
            if operation == "targets dive" then
                NyxPermanodeOperator::permanodeTargetsDive(permanode)
            end
            if operation == "targets (add new)" then
                permanode = NyxPermanodeOperator::getPermanodeByUUIDOrNull(Nyx::pathToYmir(), permanode["uuid"])
                target = NyxPermanodeOperator::makePermanodeTargetInteractiveOrNull(nil)
                next if target.nil?
                permanode["targets"] << target
                NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
            end
            if operation == "targets (select and remove)" then
                permanode = NyxPermanodeOperator::getPermanodeByUUIDOrNull(Nyx::pathToYmir(), permanode["uuid"])
                toStringLambda = lambda { |permanodeTarget| NyxPermanodeOperator::permanodeTargetToString(permanodeTarget) }
                target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", permanode["targets"], toStringLambda)
                next if target.nil?
                permanode["targets"] = permanode["targets"].reject{|t| t["uuid"]==target["uuid"] }
                NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
            end
            if operation == "tag (add new)" then
                tag = LucilleCore::askQuestionAnswerAsString("tag: ")
                next if tag.size == 0
                permanode["classification"] << {
                    "uuid" => SecureRandom.uuid,
                    "type" => "tag-18303A17",
                    "tag"  => tag
                }
                NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
            end
            if operation == "timeline (add new as string)" then
                timeline = LucilleCore::askQuestionAnswerAsString("timeline: ")
                next if timeline.size == 0
                permanode["classification"] << {
                    "uuid"     => SecureRandom.uuid,
                    "type"     => "timeline-329D3ABD",
                    "timeline" => timeline
                }
                NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
            end
            if operation == "timeline (add new select from existing)" then
                timeline = NyxPermanodeOperator::selectOneExistingTimelineOrNull()
                next if timeline.nil?
                permanode["classification"] << {
                    "uuid"     => SecureRandom.uuid,
                    "type"     => "timeline-329D3ABD",
                    "timeline" => timeline
                }
                NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
            end
            if operation == "classification (select and remove)" then
                permanode = NyxPermanodeOperator::getPermanodeByUUIDOrNull(Nyx::pathToYmir(), permanode["uuid"])
                item = LucilleCore::selectEntityFromListOfEntitiesOrNull("classification", permanode["classification"], lambda{|item| NyxPermanodeOperator::permanodeClassificationToString(item) } )
                next if item.nil?
                permanode["classification"] = permanode["classification"].reject{|i| i["uuid"]==item["uuid"] }
                NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
            end
            if operation == "edit permanode.json" then
                permanodeFilepath = NyxPermanodeOperator::permanodeFilenameToFilepathOrNull(Nyx::pathToYmir(), permanode["filename"])
                if permanodeFilepath.nil? then
                    puts "Strangely I could not find the filepath for this:"
                    puts JSON.pretty_generate(permanode)
                    LucilleCore::pressEnterToContinue()
                    next
                end
                puts "permanode filepath: #{permanodeFilepath}"
                permanodeAsJSONString = NyxMiscUtils::editTextUsingTextmate(JSON.pretty_generate(JSON.parse(IO.read(permanodeFilepath))))
                permanode = JSON.parse(permanodeAsJSONString)
                if !NyxPermanodeOperator::objectIsPermanode(permanode) then
                    puts "I do not recognise the new object as a permanode. Aborting operation."
                    next
                end
                NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
            end
            if operation == "destroy permanode" then
                if LucilleCore::askQuestionAnswerAsBoolean("Sure you want to get rid of that thing ? ") then
                    NyxPermanodeOperator::destroyPermanodeContentsAndPermanode(permanode["uuid"])
                    return
                end
            end
        }
    end

    # NyxPermanodeOperator::permanodeOptimisticOpen(permanode)
    def self.permanodeOptimisticOpen(permanode)
        NyxPermanodeOperator::printPermanodeDetails(permanode)
        puts "    -> Opening..."
        if permanode["targets"].size == 0 then
            if LucilleCore::askQuestionAnswerAsBoolean("I could not find target for this permanode. Dive? ") then
                NyxPermanodeOperator::permanodeDive(permanode)
            end
            return
        end
        target = nil
        if permanode["targets"].size == 1 then
            target = permanode["targets"].first
        else
            target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target:", permanode["targets"], lambda{|target| NyxPermanodeOperator::permanodeTargetToString(target) })
        end
        puts JSON.pretty_generate(target)
        NyxPermanodeOperator::openPermanodeTarget(Nyx::pathToYmir(), target)
    end

    # ------------------------------------------------------------------
    # Destroy

    # NyxPermanodeOperator::destroyClassificationItem(item)
    def self.destroyClassificationItem(item)
        # Honorific
        return
    end

    # NyxPermanodeOperator::destroyPermanodeTargetAttempt(target)
    def self.destroyPermanodeTargetAttempt(target)
        if target["type"] == "url-EFB8D55B" then
            url = target["url"]
            return
        end
        if target["type"] == "file-3C93365A" then
            filename = target["filename"]
            filepath = YmirEstate::locationBasenameToYmirLocationOrNull(Nyx::pathToYmir(), filename)
            if File.exists?(filepath) then
                FileUtils.rm(filepath)
            end
            return
        end
        if target["type"] == "unique-name-C2BF46D6" then
            uniquename = target["name"]
            return
        end
        if target["type"] == "lstore-directory-mark-BEE670D0" then
            location = NyxMiscUtils::lStoreMarkResolutionToMarkFilepathOrNull(target["mark"])
            return if location.nil?
            if NyxPermanodeOperator::getPermanodesCarryingThisDirectoryMark(target["mark"]).size == 1 then
                puts "destroying mark file: #{location}"
                LucilleCore::removeFileSystemLocation(location)
            end
            return
        end
        if target["type"] == "perma-dir-11859659" then
            folderpath = YmirEstate::locationBasenameToYmirLocationOrNull(Nyx::pathToYmir(), target["foldername"])
            return if folderpath.nil?
            LucilleCore::removeFileSystemLocation(folderpath)
            return
        end
        raise "[error: 15c46fdd]"
    end

    # NyxPermanodeOperator::destroyPermanodeAttempt(permanode)
    def self.destroyPermanodeAttempt(permanode)
        permanode["targets"].all?{|target| NyxPermanodeOperator::destroyPermanodeTargetAttempt(target) }
        permanode["classification"].all?{|item| NyxPermanodeOperator::destroyClassificationItem(item) }
        NyxPermanodeOperator::destroyPermanode(Nyx::pathToYmir(), permanode)
        NyxMiscUtils::publishIndex2PermanodesAsOneObject()
    end

    # NyxPermanodeOperator::destroyPermanodeContentsAndPermanode(permanodeuuid)
    def self.destroyPermanodeContentsAndPermanode(permanodeuuid)
        permanode = NyxPermanodeOperator::getPermanodeByUUIDOrNull(Nyx::pathToYmir(), permanodeuuid)
        return if permanode.nil?
        NyxPermanodeOperator::destroyPermanodeAttempt(permanode)
        NyxMiscUtils::publishIndex2PermanodesAsOneObject()
    end

end

class NyxSearch

    # NyxSearch::permanodeTargetHasSearchPattern(target, searchPattern)
    def self.permanodeTargetHasSearchPattern(target, searchPattern)
        if target["type"] == "url-EFB8D55B" then
            return true if target["url"].downcase == searchPattern.downcase
            return false
        end
        if target["type"] == "file-3C93365A" then
            return true if target["filename"].downcase == searchPattern.downcase
            return false
        end
        if target["type"] == "unique-name-C2BF46D6" then
            return true if target["name"].downcase == searchPattern.downcase
            return false
        end
        if target["type"] == "lstore-directory-mark-BEE670D0" then
            return true if target["mark"].downcase == searchPattern.downcase
            return false
        end
        if target["type"] == "perma-dir-11859659" then
            return true if target["foldername"].downcase == searchPattern.downcase
            return false
        end
        raise "[error: ab44ef72]"
    end

    # NyxSearch::permanodeTargetIncludeSearchPattern(target, searchPattern)
    def self.permanodeTargetIncludeSearchPattern(target, searchPattern)
        if target["type"] == "url-EFB8D55B" then
            return true if target["url"].downcase.include?(searchPattern.downcase)
            return false
        end
        if target["type"] == "file-3C93365A" then
            return true if target["filename"].downcase.include?(searchPattern.downcase)
            return false
        end
        if target["type"] == "unique-name-C2BF46D6" then
            return true if target["name"].downcase.include?(searchPattern.downcase)
            return false
        end
        if target["type"] == "lstore-directory-mark-BEE670D0" then
            return true if target["mark"].downcase.include?(searchPattern.downcase)
            return false
        end
        if target["type"] == "perma-dir-11859659" then
            return true if target["foldername"].downcase.include?(searchPattern.downcase)
            return false
        end
        raise "[error: 1113716b]"
    end

    # NyxSearch::permanodeSearchScore(permanode, searchPattern)
    def self.permanodeSearchScore(permanode, searchPattern)
        # 1.50 : Description is identical to search pattern
        # 1.00 : Descriprion contains search pattern as distinct word

        # 0.95 : target payload is identical to search pattern
        # 0.90 : uuid contains search pattern
        # 0.80 : Description contains search pattern

        # 0.75 : target payload is contains to search pattern
        # 0.70 : referenceDateTime contains search pattern
        # 0.60 : Timeline is identical to search pattern
        # 0.50 : Tag is identical to search pattern
        # 0.40 : Timeline contains search pattern
        # 0.30 : Tag contains search pattern
        return 1.50 if permanode["description"].downcase == searchPattern.downcase
        return 1.00 if permanode["description"].downcase.include?(" #{searchPattern.downcase} ")
        return 0.95 if permanode["targets"].any?{|target| NyxSearch::permanodeTargetHasSearchPattern(target, searchPattern) }
        return 0.90 if permanode["uuid"].downcase.include?(searchPattern.downcase)
        return 0.80 if permanode["description"].downcase.include?(searchPattern.downcase)
        return 0.75 if permanode["targets"].any?{|target| NyxSearch::permanodeTargetIncludeSearchPattern(target, searchPattern) }
        return 0.70 if permanode["referenceDateTime"].downcase.include?(searchPattern.downcase)
        return 0.60 if permanode["classification"].select{|item| item["type"] == "timeline-329D3ABD" }.any?{|item| item["timeline"].downcase == searchPattern.downcase }
        return 0.50 if permanode["classification"].select{|item| item["type"] == "tag-18303A17"      }.any?{|item| item["tag"].downcase == searchPattern.downcase }
        return 0.40 if permanode["classification"].select{|item| item["type"] == "timeline-329D3ABD" }.any?{|item| item["timeline"].downcase.include?(searchPattern.downcase) }
        return 0.30 if permanode["classification"].select{|item| item["type"] == "tag-18303A17"      }.any?{|item| item["tag"].downcase.include?(searchPattern.downcase) }
        0
    end

    # NyxSearch::permanodeSearchScorePacket(permanode, searchPattern):
    def self.permanodeSearchScorePacket(permanode, searchPattern)
        {
            "permanode" => permanode,
            "score" => NyxSearch::permanodeSearchScore(permanode, searchPattern)
        }
    end

    # NyxSearch::searchPatternToScorePacketsInDecreasingScore(searchPattern)
    def self.searchPatternToScorePacketsInDecreasingScore(searchPattern) # Array[ScorePackets]
        NyxPermanodeOperator::permanodesEnumerator(Nyx::pathToYmir())
            .map{|permanode| NyxSearch::permanodeSearchScorePacket(permanode, searchPattern) }
            .sort{|p1, p2| p1["score"]<=>p2["score"] }
            .reverse
    end

end

class NyxUserInterface

    # ------------------------------------------
    # Workflows

    # NyxUserInterface::permanodesDive(permanodes)
    def self.permanodesDive(permanodes)
        loop {
            permanode = NyxUserInterface::selectPermanodeOrNull(permanodes)
            break if permanode.nil?
            NyxPermanodeOperator::permanodeDive(permanode)
        }
    end

    # NyxUserInterface::searchDive(searchPattern)
    def self.searchDive(searchPattern)
        loop {
            scorePackets = NyxSearch::searchPatternToScorePacketsInDecreasingScore(searchPattern).select{|scorePacket| scorePacket["score"] > 0 }
            scorePacket = NyxUserInterface::selectScorePacketOrNull(scorePackets)
            break if scorePacket.nil?
            NyxPermanodeOperator::permanodeDive(scorePacket["permanode"])
        }
    end

    # NyxUserInterface::searchOpen(searchPattern)
    def self.searchOpen(searchPattern)
        loop {
            scorePackets = NyxSearch::searchPatternToScorePacketsInDecreasingScore(searchPattern).select{|scorePacket| scorePacket["score"] > 0 }
            scorePacket = NyxUserInterface::selectScorePacketOrNull(scorePackets)
            break if scorePacket.nil?
            NyxPermanodeOperator::permanodeOptimisticOpen(scorePacket["permanode"])
        }
    end

    # NyxUserInterface::selectPermanodeOrNull(permanodes)
    def self.selectPermanodeOrNull(permanodes)
        descriptionXp = lambda { |permanode|
            "#{permanode["description"]} (#{permanode["uuid"][0,4]})"
        }
        descriptionsxp = permanodes.map{|permanode| descriptionXp.call(permanode) }
        selectedDescriptionxp = NyxMiscUtils::chooseALinePecoStyle("select permanode (empty for null)", [""] + descriptionsxp)
        return nil if selectedDescriptionxp == ""
        permanode = permanodes.select{|permanode| descriptionXp.call(permanode) == selectedDescriptionxp }.first
        return nil if permanode.nil?
        permanode
    end

    # NyxUserInterface::selectScorePacketOrNull(scorePackets)
    def self.selectScorePacketOrNull(scorePackets)
        descriptionXp = lambda { |scorePacket|
            permanode = scorePacket["permanode"]
            "[#{scorePacket["score"]}] #{permanode["description"]} (#{permanode["uuid"][0,4]})"
        }
        descriptionsxp = scorePackets.map{|scorePacket| descriptionXp.call(scorePacket) }
        selectedDescriptionxp = NyxMiscUtils::chooseALinePecoStyle("select scored permanode (empty for null)", [""] + descriptionsxp)
        return nil if selectedDescriptionxp == ""
        scorePacket = scorePackets.select{|scorePacket| descriptionXp.call(scorePacket) == selectedDescriptionxp }.first
        return nil if scorePacket.nil?
        scorePacket
    end

    # NyxUserInterface::uimainloop()
    def self.uimainloop()
        loop {
            system("clear")
            puts "Nyx 🗺️"
            operations = [
                # Search
                "search",

                # View
                "permanode dive (uuid)",
                "show newly created permanodes",
                "select and dive timeline",

                # Make or modify
                "make new permanode",
                "rename tag or timeline",
                "repair permanode (uuid)",

                # Special operations
                "publish dump for Night",
                "curation",

                # Destroy
                "permanode destroy (uuid)",
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            break if operation.nil?
            if operation == "search" then
                searchPattern = LucilleCore::askQuestionAnswerAsString("search: ")
                NyxUserInterface::searchDive(searchPattern)
            end
            if operation == "permanode dive (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                permanode = NyxPermanodeOperator::getPermanodeByUUIDOrNull(Nyx::pathToYmir(), uuid)
                if permanode then
                    NyxPermanodeOperator::permanodeDive(permanode)
                else
                    puts "Could not find permanode for uuid (#{uuid})"
                end
            end
            if operation == "repair permanode (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                permanode = NyxPermanodeOperator::getPermanodeByUUIDOrNull(Nyx::pathToYmir(), uuid)
                next if permanode.nil?
                filepath = NyxPermanodeOperator::permanodeFilenameToFilepathOrNull(Nyx::pathToYmir(), permanode["filename"])
                next if filepath.nil?
                system("open '#{filepath}'")
                LucilleCore::pressEnterToContinue()
            end

            if operation == "make new permanode" then
                NyxPermanodeOperator::makePermanodeInteractive()
            end
            if operation == "publish dump for Night" then
                NyxMiscUtils::publishIndex2PermanodesAsOneObject()
            end
            if operation == "show newly created permanodes" then
                permanodes = NyxPermanodeOperator::permanodesEnumerator(Nyx::pathToYmir())
                NyxPermanodeOperator::applyReferenceDateTimeOrderToPermanodes(permanodes)
                    .reverse
                    .first(20)
                NyxUserInterface::permanodesDive(permanodes)
            end
            if operation == "select and dive timeline" then
                timeline = NyxMiscUtils::chooseALinePecoStyle("timeline:", [""] + NyxPermanodeOperator::timelinesInDecreasingActivityDateTime())
                next if timeline.size == 0
                permanodes = NyxPermanodeOperator::getTimelinePermanodes(timeline)
                NyxUserInterface::permanodesDive(permanodes)
            end
            if operation == "curation" then
                NyxCuration::curate()
            end
            if operation == "rename tag or timeline" then
                renameClassificationValue = lambda{|value, oldName, newName|
                    if value.downcase == oldName.downcase then
                        value = newName
                    end
                    value
                }
                transformClassificationTagObject = lambda{|object, oldName, newName|
                    object["tag"] = renameClassificationValue.call(object["tag"], oldName, newName)
                    object
                }
                transformClassificationTimelineObject = lambda{|object, oldName, newName|
                    object["timeline"] = renameClassificationValue.call(object["timeline"], oldName, newName)
                    object
                }
                transformClassificationItem = lambda{|item, oldName, newName|
                    if item["type"] == "tag-18303A17" then
                        item = transformClassificationTagObject.call(item.clone, oldName, newName)
                    end
                    if item["type"] == "timeline-329D3ABD" then
                        item = transformClassificationTimelineObject.call(item.clone, oldName, newName)
                    end
                    item
                }
                transformPermanode = lambda{|permanode, oldName, newName|
                    permanode["classification"] = permanode["classification"]
                                                    .map{|classificationItem|
                                                        transformClassificationItem.call(classificationItem.clone, oldName, newName) 
                                                    }
                    permanode
                }
                oldName = LucilleCore::askQuestionAnswerAsString("old name: ")
                newName = LucilleCore::askQuestionAnswerAsString("new name: ")
                NyxPermanodeOperator::permanodesEnumerator(Nyx::pathToYmir())
                    .each{|permanode| 
                        permanode2 = transformPermanode.call(permanode.clone, oldName, newName)
                        if permanode.to_s != permanode2.to_s then
                            puts JSON.pretty_generate(permanode)
                            puts "I am running on empty, you need to check visually and uncomment the line"
                            puts JSON.pretty_generate(permanode2)
                            #NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode2)
                        end
                    }
                NyxMiscUtils::publishIndex2PermanodesAsOneObject()
            end
            if operation == "permanode destroy (uuid)" then
                permanodeuuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                if LucilleCore::askQuestionAnswerAsBoolean("Sure you want to get rid of that thing ? ") then
                    NyxPermanodeOperator::destroyPermanodeContentsAndPermanode(permanodeuuid)
                end
            end
        }
    end
end

class Nyx

    # Nyx::pathToYmir()
    def self.pathToYmir()
        "/Users/pascal/Galaxy/Nyx"
    end

end
