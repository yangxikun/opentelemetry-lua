---
title: Changelog
---

## Table of Contents

- [0.2-2](#022)
- [0.2-1](#021)
- [0.2-0](#020)
- [0.1-3](#013)
- [0.1-2](#012)
- [0.1-1](#011)
- [0.1-0](#010)

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