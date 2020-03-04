#!/usr/bin/ruby

# encoding: UTF-8

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"

DATABANK_FOLDER_PATH = "/Users/pascal/Galaxy/DataBank"
DATABANK_CATALYST_FOLDERPATH = "#{DATABANK_FOLDER_PATH}/Catalyst"
CATALYST_BIN_TIMELINE_FOLDERPATH = "#{DATABANK_CATALYST_FOLDERPATH}/Bin-Timeline"

class CatalystCommon

    # CatalystCommon::newBinArchivesFolderpath()
    def self.newBinArchivesFolderpath()
        time = Time.new
        folder1 = "#{CATALYST_BIN_TIMELINE_FOLDERPATH}/#{time.strftime("%Y")}/#{time.strftime("%Y-%m")}/#{time.strftime("%Y-%m-%d")}"
        folder2 = LucilleCore::indexsubfolderpath(folder1)
        folder3 = "#{folder2}/#{time.strftime("%Y%m%d-%H%M%S-%6N")}"
        FileUtils.mkpath(folder3)
        folder3
    end

    # CatalystCommon::copyLocationToCatalystBin(location)
    def self.copyLocationToCatalystBin(location)
        return if location.nil?
        return if !File.exists?(location)
        targetFolder = CatalystCommon::newBinArchivesFolderpath()
        LucilleCore::copyFileSystemLocation(location,targetFolder)
    end

end
