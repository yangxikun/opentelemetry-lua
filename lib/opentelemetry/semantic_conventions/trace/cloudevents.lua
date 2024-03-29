--- This file was automatically generated by utils/generate_semantic_conventions.lua
-- See: https://github.com/open-telemetry/opentelemetry-specification/tree/main/specification/trace/semantic_conventions
--
-- module @semantic_conventions.trace.cloudevents
local _M = {
    -- The [event_id](https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/spec.md#id) uniquely identifies the event.
    CLOUDEVENTS_EVENT_ID = "cloudevents.event_id",
    -- The [source](https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/spec.md#source-1) identifies the context in which an event happened.
    CLOUDEVENTS_EVENT_SOURCE = "cloudevents.event_source",
    -- The [version of the CloudEvents specification](https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/spec.md#specversion) which the event uses.
    CLOUDEVENTS_EVENT_SPEC_VERSION = "cloudevents.event_spec_version",
    -- The [event_type](https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/spec.md#type) contains a value describing the type of event related to the originating occurrence.
    CLOUDEVENTS_EVENT_TYPE = "cloudevents.event_type",
    -- The [subject](https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/spec.md#subject) of the event in the context of the event producer (identified by source).
    CLOUDEVENTS_EVENT_SUBJECT = "cloudevents.event_subject"
}
return _M
