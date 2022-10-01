package main

import (
	"context"
	"io/ioutil"
	"log"
	"net/http"
	"os"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.7.0"
	"go.opentelemetry.io/otel/trace"
)

// Initializes an OTLP exporter, and configures the corresponding trace and
// metric providers.
func initProvider() func() {
	ctx := context.Background()

	res, err := resource.New(ctx,
		resource.WithAttributes(
			// the service name used to display traces in backends
			semconv.ServiceNameKey.String("test-client"),
		),
	)
	handleErr(err, "failed to create resource")

	// If the OpenTelemetry Collector is running on a local cluster (minikube or
	// microk8s), it should be accessible through the NodePort service at the
	// `localhost:30080` endpoint. Otherwise, replace `localhost` with the
	// endpoint of your cluster. If you run the app inside k8s, then you can
	// probably connect directly to the service through dns

	// Set up a trace exporter
	traceExporter, err := otlptracehttp.New(ctx, otlptracehttp.WithEndpoint("otel-collector:4317"), otlptracehttp.WithInsecure(),
		otlptracehttp.WithHeaders(map[string]string{
			"Content-Type": "application/json",
		}))
	handleErr(err, "failed to create trace exporter")

	// Register the trace exporter with a TracerProvider, using a batch
	// span processor to aggregate spans before export.
	bsp := sdktrace.NewBatchSpanProcessor(traceExporter)
	tracerProvider := sdktrace.NewTracerProvider(
		sdktrace.WithSampler(sdktrace.AlwaysSample()),
		sdktrace.WithResource(res),
		sdktrace.WithSpanProcessor(bsp),
	)
	otel.SetTracerProvider(tracerProvider)

	// set global propagator to tracecontext (the default is no-op).
	otel.SetTextMapPropagator(propagation.TraceContext{})

	return func() {
		// Shutdown will flush any remaining spans and shut down the exporter.
		handleErr(tracerProvider.Shutdown(ctx), "failed to shutdown TracerProvider")
	}
}

func main() {
	shutdown := initProvider()
	defer shutdown()

	tracer := otel.Tracer("test-client-tracer")
	traceState, err := trace.ParseTraceState("trace-state-example-key=trace-state-example-val")
	handleErr(err, "parse trace state failed")
	ctx := trace.ContextWithSpanContext(context.Background(), trace.NewSpanContext(trace.SpanContextConfig{
		TraceState: traceState,
	}))
	ctx, span := tracer.Start(ctx, "test-client-span", trace.WithSpanKind(trace.SpanKindClient))
	defer span.End()

	span.SetStatus(codes.Error, "client side failed")

	req, err := http.NewRequest("GET", os.Getenv("PROXY_ENDPOINT"), nil)
	handleErr(err, "new request fail")

	propagation.TraceContext{}.Inject(ctx, propagation.HeaderCarrier(req.Header))
	rsp, err := http.DefaultClient.Do(req)
	handleErr(err, "request fail")

	body, err := ioutil.ReadAll(rsp.Body)
	handleErr(err, "read body fail")

	log.Println(string(body))
	_ = rsp.Body.Close()
}

func handleErr(err error, message string) {
	if err != nil {
		log.Fatalf("%s: %v", message, err)
	}
}
