# Nyx

## History

The original Nyx was a command line tool and web interface used by Pascal as a [Personal Information Management system](https://en.wikipedia.org/wiki/Personal_information_management). In **2015**, I wrote a [detailed entry](http://weblog.alseyn.net/index.php?uuid=40bd59d4-48de-454a-9a50-2c2a1c919e32) about what Nyx fundamentally is, and how it was built at the time.

## Permanodes


```
{
    "uuid"              : String
    "filename"          : String # Should be unique # Preferred L22
    "creationTimestamp" : Float
    "referenceDateTime" : DateTime Iso8601
    "description"       : String
    "targets"           : Array[PermanodeTarget]
    "tags"              : Array[String]
    "arrows"            : Array[String]
}
```

- And example of `DateTime Iso8601` is `2018-12-06T23:23:48Z`. 

- `referenceDateTime` is usually fixed and used to give dating to the data referenced by the permanode.

- `PermanodeTarget` is a union of the following types

    ```
    {
        "uuid" : String
        "type" : "url-EFB8D55B"
        "url"  : <url>
    }
    {
        "uuid"       : String UUID
        "type"       : "file-3C93365A"
        "filename"   : String
    }
    {
        "uuid" : String
        "type" : "unique-name-C2BF46D6"
        "name" : String
    }
    {
        "uuid" : String
        "type" : "lstore-directory-mark-BEE670D0"
        "mark" : String # UUID
    }
    {
        "uuid"       : String UUID
        "type"       : "perma-dir-11859659"
        "foldername" : String # Should be unique # Preferred L22
    }
    ```

## PermaDirs

**PermaDirs** are just directories, with fixed immutable foldernames. The uuid of the `perma-dir-11859659` object is the name of the corresponding directory. They are a more controlled version of general directories with marks (those that are targets of `lstore-directory-mark-BEE670D0` objects).

## Tags and Arrows

The overall organization of the Nyx system is that of tags, and tags connected by arrows. The direction is meant to represent semantic flows in Pascal's mind.

For instance a picture of Justin Bieber represented by a permanode might come with tag "Paris" (if, say, the picture was taken in Paris) and we might also have an arrow from "Canada" to "Justin Bieber".

Example: 

```
tags: ["Paris"]
arrows: ["Canada -> Justin Bieber"]
```

For searching the permanode will show up when searching for "Paris" and searching for "Justin Bieber". If one search for "Canada", then the arrow will show up. In other words the permanode belongs to its tags and the end of its arrows.

## Dependencies

Nyx has a dependency on `peco` [https://github.com/peco/peco](https://github.com/peco/peco), which is used as part of the command line user interface.

