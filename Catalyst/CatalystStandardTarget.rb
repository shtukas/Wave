
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/CatalystStandardTarget.rb"
=begin
    CatalystStandardTarget::locationToTargetOrNullIfBasenameIsCurrent(location)
    CatalystStandardTarget::makeNewTargetInteractivelyOrNull()
    CatalystStandardTarget::targetToString(target)
    CatalystStandardTarget::openTarget(target)
=end

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/CoreData.rb"
=begin
    CoreDataFile::copyFileToRepository(filepath)
    CoreDataFile::filenameToFilepath(filename)
    CoreDataFile::exists?(filename)
    CoreDataFile::openOrCopyToDesktop(filename)

    CoreDataDirectory::copyFolderToRepository(folderpath)
    CoreDataDirectory::foldernameToFolderpath(foldername)
    CoreDataDirectory::exists?(foldername)
    CoreDataDirectory::openFolder(foldername)
=end

# -----------------------------------------------------------------

class CatalystStandardTarget

    # CatalystStandardTarget::locationToTargetOrNullIfBasenameIsCurrent(location)
    def self.locationToTargetOrNullIfBasenameIsCurrent(location)
        raise "f8e3b314" if !File.exists?(location)
        if File.file?(location) then
            return nil if CoreDataFile::exists?(File.basename(location))
            CoreDataFile::copyFileToRepository(location)
            {
                "type"     => "file",
                "filename" => File.basename(location)
            }
        else
            return nil if CoreDataDirectory::exists?(File.basename(location))
            CoreDataDirectory::copyFolderToRepository(location)
            {
                "type"       => "folder",
                "foldername" => File.basename(location)
            }
        end
    end

    # CatalystStandardTarget::makeNewTargetInteractivelyOrNull()
    def self.makeNewTargetInteractivelyOrNull()
        types = ["line", "file", "url", "folder"]
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", types)
        return if type.nil?
        if type == "line" then
            line = LucilleCore::askQuestionAnswerAsString("line: ")
            return {
                "type" => "line",
                "line" => line
            }
        end
        nil
    end

    # CatalystStandardTarget::targetToString(target)
    def self.targetToString(target)
        if target["type"] == "line" then
            return target["line"]
        end
        if target["type"] == "file" then
            return "CoreData file: #{target["filename"]}"
        end
        if target["type"] == "url" then
            return target["url"]
        end
        if target["type"] == "folder" then
            return "CoreData folder: #{target["foldername"]}"
        end
        raise "Catalyst Standard Target error 3c7968e4"
    end

    # CatalystStandardTarget::openTarget(target)
    def self.openTarget(target)
        if target["type"] == "line" then
            puts target["line"]
            LucilleCore::pressEnterToContinue()
            return
        end
        if target["type"] == "file" then
            CoreDataFile::openOrCopyToDesktop(target["filename"])
            return
        end
        if target["type"] == "url" then
            system("open '#{target["url"]}'")
            return
        end
        if target["type"] == "folder" then
            CoreDataDirectory::openFolder(target["foldername"])
            return
        end
        raise "Catalyst Standard Target error 160050-490261"
    end

    # CatalystStandardTarget::fsckTarget(target)
    def self.fsckTarget(target)
        if target["type"].nil? then
            puts target
            raise "target as no type"
        end
        if target["type"] == "line" then
            if target["line"].nil? then
                puts target
                raise "target as no line"
            end
        end
        if target["type"] == "file" then
            if target["filename"].nil? then
                puts target
                raise "target as no filename"
            end
            status = CoreDataFile::exists?(target["filename"])
            if !status then
                puts target
                raise "CoreDataFile cannot find this filename: #{target["filename"]}"
            end
        end
        if target["type"] == "url" then
        end
        if target["type"] == "folder" then
            if target["foldername"].nil? then
                puts target
                raise "target as no foldername"
            end
            status = CoreDataDirectory::exists?(target["foldername"])
            if !status then
                puts target
                raise "CoreDataFile cannot find this foldername: #{target["foldername"]}"
            end
        end
    end
end