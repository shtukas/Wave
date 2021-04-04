
# encoding: UTF-8

class Patricia

    # Patricia::isNereidElement(element)
    def self.isNereidElement(element)
        !element["payload"].nil?
    end

    # Patricia::isWave(object)
    def self.isWave(object)
        object["nyxNxSet"] == "7deb0315-98b5-4e4d-9ad2-d83c2f62e6d4"
    end

    # Patricia::isQuark(object)
    def self.isQuark(object)
        object["nyxNxSet"] == "d65674c7-c8c4-4ed4-9de9-7c600b43eaab"
    end

    # Patricia::isNX141FSCacheElement(element)
    def self.isNX141FSCacheElement(element)
        element["nyxElementType"] == "736ec8c8-daa6-48cf-8d28-84cfca79bedc"
    end

    # Patricia::isNyxNavigationPoint(item)
    def self.isNyxNavigationPoint(item)
        item["identifier1"] == "103df1ac-2e73-4bf1-a786-afd4092161d4"
    end

    # -------------------------------------------------------

    # Patricia::getNyxNetworkNodeByUUIDOrNull(uuid)
    def self.getNyxNetworkNodeByUUIDOrNull(uuid)
        item = NereidInterface::getElementOrNull(uuid)
        return item if item

        item = NX141FSCacheElement::getElementByUUIDOrNull(uuid)
        return item if item

        item = NyxNavigationPoints::getNavigationPointByUUIDOrNull(uuid)
        return item if item

        nil
    end

    # Patricia::toString(item)
    def self.toString(item)
        if Patricia::isNereidElement(item) then
            return NereidInterface::toString(item)
        end
        if Patricia::isNX141FSCacheElement(item) then
            return NX141FSCacheElement::toString(item)
        end
        if Patricia::isNyxNavigationPoint(item) then
            return NyxNavigationPoints::toString(item)
        end
        if Patricia::isQuark(item) then
            return Quarks::toString(item)
        end
        if Patricia::isWave(item) then
            return Waves::toString(item)
        end
        puts item
        raise "[error: d4c62cad-0080-4270-82a9-81b518c93c0e]"
    end

    # Patricia::landing(item)
    def self.landing(item)
        if Patricia::isNereidElement(item) then
            NereidNyxExt::landing(item)
            return
        end
        if Patricia::isNX141FSCacheElement(item) then
            NX141FSCacheElement::landing(item)
            return
        end
        if Patricia::isNyxNavigationPoint(item) then
            NyxNavigationPoints::landing(item)
            return
        end
        if Patricia::isQuark(item) then
            Quarks::landing(item)
            return
        end
        if Patricia::isWave(item) then
            Waves::landing(item)
            return 
        end
        puts item
        raise "[error: fb2fb533-c9e5-456e-a87f-0523219e91b7]"
    end

    # -------------------------------------------------------

    # Patricia::selectOneNodeOrNull()
    def self.selectOneNodeOrNull()
        searchItem = CatalystUtils::selectOneObjectOrNullUsingInteractiveInterface(Patricia::nyxSearchItemsAll(), lambda{|item| item["announce"] })
        return nil if searchItem.nil?
        searchItem["payload"]
    end
    
    # Patricia::selectExistingOrMakeNewNodeOrNull()
    def self.selectExistingOrMakeNewNodeOrNull()
        node = Patricia::selectOneNodeOrNull()
        return node if node
        Patricia::makeNewNodeOrNull()
    end

    # Patricia::linkToArchitectedNode(item)
    def self.linkToArchitectedNode(item)
        e1 = Patricia::selectExistingOrMakeNewNodeOrNull()
        return if e1.nil?
        Network::link(item, e1)
    end

    # Patricia::selectAndRemoveLinkedNode(item)
    def self.selectAndRemoveLinkedNode(item)
        related = Network::getLinkedObjects(item)
        return if related.empty?
        node = LucilleCore::selectEntityFromListOfEntitiesOrNull("related", related, lambda{|node| Patricia::toString(node) })
        return if node.nil?
        Network::unlink(item, node)
    end

    # -------------------------------------------------------

    # Patricia::nyxSearchItemsAll()
    def self.nyxSearchItemsAll()
        searchItems = [
            NereidNyxExt::nyxSearchItems(),
            NX141FSCacheElement::nyxSearchItems(),
            NyxNavigationPoints::nyxSearchItems()
        ]
        .flatten
    end

    # Patricia::generalSearchLoop()
    def self.generalSearchLoop()
        loop {
            dx7 = Patricia::selectOneNodeOrNull()
            break if dx7.nil? 
            Patricia::landing(dx7)
        }
    end

    # -------------------------------------------------------
end