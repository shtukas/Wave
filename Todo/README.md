# Todo

```
{
    "uuid"              : String
    "filename"          : String # Should be unique # Preferred L22
    "creationTimestamp" : Float
    "description"       : String
    "targets"           : Array[Target]
    "classification"    : Array[ClassificationItem]
}
```

- And example of `DateTime Iso8601` is `2018-12-06T23:23:48Z`. 

- `referenceDateTime` is usually fixed and used to give dating to the data referenced by the permanode.

- `Target` is a union of the following types

    ```
    {
        "uuid" : String
        "type" : "lstore-directory-mark-BEE670D0"
        "mark" : String # UUID
    }
    {
        "uuid" : String
        "type" : "url-EFB8D55B"
        "url"  : <url>
    }
    {
        "uuid" : String
        "type" : "unique-name-C2BF46D6"
        "name" : String
    }
    {
        "uuid"       : String UUID
        "type"       : "perma-dir-11859659"
        "foldername" : String # Should be unique # Preferred L22
    }
    {
        "uuid": String,
        "type": "text-A9C3641C",
        "filename": String
    }
    {
        "uuid": String,
        "type": "line-2A35BA23",
        "line": String # Line
    }
    ```

- `ClassificationItem` is a union of the following types

    ```
    {
        "uuid"     : String
        "type"     : "tag-18303A17"
        "tag"      : String
    }
    {
        "uuid"     : String
        "type"     : "timeline-329D3ABD"
        "timeline" : String
    }
    ```

### Limitations

TNodes get their shapes from the general Nyx Permanodes, but we impose limitations on them

- No tags
- Only one target
- Only one timelime