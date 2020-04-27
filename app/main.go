package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"go.opentelemetry.io/otel/api/core"
	"go.opentelemetry.io/otel/api/global"
	"go.opentelemetry.io/otel/api/key"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"

	"go.opentelemetry.io/otel/exporters/trace/jaeger"
)

const (
	appName = "hello-opentelemetry"
)

type flushFunc func()

func main() {
	flush := initTracer(appName)
	defer flush()
	http.HandleFunc("/health", func(w http.ResponseWriter, req *http.Request) {
		fmt.Fprintf(w, "OK")
	})
	http.HandleFunc("/hello", func(w http.ResponseWriter, req *http.Request) {
		_, span := global.Tracer(appName).Start(context.Background(), "mySpan")
		defer span.End()

		time.Sleep(1 * time.Second)

		fmt.Fprintf(w, "hey\n")
	})
	http.ListenAndServe(os.ExpandEnv(":${PORT}"), nil)
}

func initTracer(appName string) flushFunc {
	// Create and install Jaeger export pipeline
	_, flush, err := jaeger.NewExportPipeline(
		jaeger.WithCollectorEndpoint(os.ExpandEnv("${COLLECTOR_ADDR}/api/traces")),
		jaeger.WithProcess(jaeger.Process{
			ServiceName: appName,
			Tags: []core.KeyValue{
				key.String("exporter", "jaeger"),
				key.Float64("float", 312.23),
			},
		}),
		jaeger.RegisterAsGlobal(),
		jaeger.WithSDK(&sdktrace.Config{DefaultSampler: sdktrace.AlwaysSample()}),
	)

	if err != nil {
		log.Fatal(err)
	}

	return flush
}
