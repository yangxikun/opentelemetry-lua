---
title: Changelog
---

## Table of Contents

- [0.2-6](#0.2-6)
- [0.2-5](#0.2-5)
- [0.2-4](#0.2-4)
- [0.2-3](#0.2-3)
- [0.2-2](#0.2-2)
- [0.2-1](#0.2-1)
- [0.2-0](#0.2-0)
- [0.1-3](#0.1-3)
- [0.1-2](#0.1-2)
- [0.1-1](#0.1-1)
- [0.1-0](#0.1-0)


## 0.2-6

### Change

- feature: allow user to specify start time for new recording span yangxikun/opentelemetry-lua#86

### Bugfix

- duplicate trace ids in high requests distributed system yangxikun/opentelemetry-lua#95


## 0.2-5

### Change

- feature: attribute support array_value type yangxikun/opentelemetry-lua#82
- improve: add resource attrs to console export yangxikun/opentelemetry-lua#91
- improve: allow multiple tracer providers or tracers for export yangxikun/opentelemetry-lua#92

### Bugfix

- Baggage header parsing should remove leading and trailing whitespaces in k/v, yangxikun/opentelemetry-lua#77

## 0.2-4

### Change

- improve: speed up id generator yangxikun/opentelemetry-lua#74
- feature: add semantic conventions yangxikun/opentelemetry-lua#66

## 0.2-3

### Change

- feature: exporter client support https yangxikun/opentelemetry-lua#60
- breaking: span_status field name changed to uppercase yangxikun/opentelemetry-lua#59

### Bugfix

- context.with_span need copy the parent context's entries yangxikun/opentelemetry-lua#58

## 0.2-2

### Change

- feature: add simple span processor
- enhancement: allow users to specify multiple span processors
- enhancement: allow user to specify end timestamp when finishing span
- feature: add tracestate handling

## 0.2-1

### Change

- enhancement: trace exporter add exponential backoff and circuit breaker when failed to exporting spans
- feature: add console exporter for debugging
- feature: support [baggage](https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/baggage/api.md)
- feature: add metrics reporter
- feature: add tracestate to exports
- breaking: refactor context, `context.attach` will return a token, and need to be passed to `context.detach`

### Bugfix

- fix data race in batch_span_processor

## 0.2-0

### Change

- enhancement: support export spans on exit
- enhancement: exporter http_client use keepalive
- breaking: propagation api change

## 0.1-3

### Bugfix

- exporter: hex2bytes may panic if traceID is invalid

## 0.1-2

### Bugfix

- batch_span_processor export zero length spans. apache/apisix#6329

## 0.1-1

### Bugfix

- batch_span_processor fail on openresty log_by_lua phase 
- batch_span_processor.shutdown should not set exporter=nil

### Change

- enhancement: batch_span_processor avoid useless timer
- feat: exporter http client support custom headers
- feat: refactor id_generator

## 0.1-0