# logstash-input-twitch

## Milestone: 1

Logstash input to get Twitch stream stats

## Configuration

input {
  twitch {
    channels =>  ... # array (required)
    interval => ... # integer (optional), default is 60 seconds
    type => ... # string (optional)
  }
}

## Details

### channels (required setting)

* Value type is array
* There is no default value for this setting

An array of all channels you want to query.

### interval

* Value type is integer
* Default is 60

The interval in seconds in which this plugin is executed.

### type

* Value type is string
* There is no default value for this setting

Add a type field to all events handled by this plugin.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in the web interface.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.
