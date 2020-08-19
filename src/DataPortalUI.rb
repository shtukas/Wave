# encoding: UTF-8

class DataPortalUI

    # DataPortalUI::dataPortalFront()
    def self.dataPortalFront()
        loop {
            system("clear")

            ms = LCoreMenuItemsNX1.new()

            ms.item(
                "Catalyst General Search", 
                lambda { GeneralSearch::searchAndDive() }
            )

            ms.item(
                "Node Search", 
                lambda { NSDT1SelectionInterface::interactiveSearchAndExplore() }
            )

            ms.item(
                "Node listing", 
                lambda {
                    nodes = NSDataType1::objects()
                    nodes = GenericObjectInterface::applyDateTimeOrderToObjects(nodes)
                    loop {
                        system("clear")
                        node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", nodes, lambda{|o| NSDataType1::toString(o) })
                        break if node.nil?
                        NSDataType1::landing(node)
                    }
                }
            )

            puts ""

            ms.item(
                "new data",
                lambda {
                    puts "We first select a node because a dataline without a parent will be garbage collected"
                    LucilleCore::pressEnterToContinue()
                    node = NSDT1SelectionInterface::selectNodeSpecialWeaponsAndTactics()
                    return if node.nil?
                    puts "selected node: #{NSDataType1::toString(node)}"
                    LucilleCore::pressEnterToContinue()
                    dataline = NSDataLine::interactiveIssueNewDatalineWithItsFirstPointOrNull()
                    return if dataline.nil?
                    Arrows::issueOrException(node, dataline)
                    description = LucilleCore::askQuestionAnswerAsString("dataline description ? (empty for null) : ")
                    if description.size > 0 then
                        NSDataTypeXExtended::issueDescriptionForTarget(dataline, description)
                    end
                    NSDataType1::landing(node)
                }
            )

            ms.item(
                "new node",
                lambda { 
                    point = NSDataType1::issueNewNodeInteractivelyOrNull()
                    return if point.nil?
                    NSDataType1::landing(point)
                }
            )

            ms.item(
                "Merge two nodes",
                lambda { 
                    puts "Merging two nodes"
                    puts "Selecting one after the other and then will merge"
                    node1 = NSDT1SelectionInterface::sandboxSelectionOfOneExistingNodeOrNull()
                    return if node1.nil?
                    node2 = NSDT1SelectionInterface::sandboxSelectionOfOneExistingNodeOrNull()
                    return if node2.nil?
                    if node1["uuid"] == node2["uuid"] then
                        puts "You have selected the same node twice. Aborting merge operation."
                        LucilleCore::pressEnterToContinue()
                        return
                    end

                    puts ""
                    puts NSDataType1::toString(node1)
                    puts NSDataType1::toString(node2)

                    return if !LucilleCore::askQuestionAnswerAsBoolean("confirm merge : ")

                    # Moving all the node upstreams of node2 towards node 1
                    Arrows::getSourcesForTarget(node2).each{|x|
                        Arrows::issueOrException(x, node1)
                    }
                    # Moving all the downstreams of node2 toward node 1
                    Arrows::getTargetsForSource(node2).each{|x|
                        Arrows::issueOrException(node1, x)
                    }
                    NyxObjects2::destroy(node2) # Simple destroy, not the procedure,what happens if node2 had some contents ?
                }
            )

            ms.item(
                "dangerously edit a nyx object by uuid", 
                lambda { 
                    uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                    return if uuid == ""
                    object = NyxObjects2::getOrNull(uuid)
                    return if object.nil?
                    object = Miscellaneous::editTextSynchronously(JSON.pretty_generate(object))
                    object = JSON.parse(object)
                    NyxObjects2::destroy(object)
                    NyxObjects2::put(object)
                }
            )

            puts ""

            ms.item(
                "Asteroids",
                lambda { Asteroids::main() }
            )

            ms.item(
                "asteroid (new)",
                lambda { 
                    asteroid = Asteroids::issueAsteroidInteractivelyOrNull()
                    return if asteroid.nil?
                    puts JSON.pretty_generate(asteroid)
                    LucilleCore::pressEnterToContinue()
                }
            )

            ms.item(
                "asteroid floats open-project-in-the-background", 
                lambda { 
                    loop {
                        system("clear")
                        menuitems = LCoreMenuItemsNX1.new()
                        Asteroids::asteroids()
                            .select{|asteroid| asteroid["orbital"]["type"] == "open-project-in-the-background-b458aa91-6e1" }
                            .each{|asteroid|
                                menuitems.item(
                                    Asteroids::toString(asteroid),
                                    lambda { Asteroids::landing(asteroid) }
                                )
                            }
                        status = menuitems.prompt()
                        break if !status
                    }
                }
            )

            puts ""

            ms.item(
                "Calendar",
                lambda { 
                    system("open '#{Miscellaneous::catalystDataCenterFolderpath()}/Calendar/Items'") 
                }
            )

            ms.item(
                "Waves",
                lambda { Waves::main() }
            )

            puts ""

            ms.item(
                "rebuild node search lookup table", 
                lambda { NSDT1SelectionDatabaseInterface::rebuildLookup() }
            )

            ms.item(
                "rebuild dataline search lookup table", 
                lambda { NSDataLinePatternSearchLookup::rebuildLookup() }
            )

            ms.item(
                "Print Generation Speed Report", 
                lambda { CatalystObjectsOperator::generationSpeedReport() }
            )

            ms.item(
                "Curation::session()", 
                lambda { Curation::session() }
            )

            ms.item(
                "DeskOperator::commitDeskChangesToPrimaryRepository()", 
                lambda { DeskOperator::commitDeskChangesToPrimaryRepository() }
            )

            ms.item(
                "NyxGarbageCollection::run()", 
                lambda { NyxGarbageCollection::run() }
            )

            ms.item(
                "Archive timeline garbage collection", 
                lambda { 
                    puts "#{EstateServices::getArchiveT1mel1neSizeInMegaBytes()} Mb"
                    EstateServices::binTimelineGarbageCollectionEnvelop(true)
                }
            )

            status = ms.prompt()
            break if !status
        }
    end
end


