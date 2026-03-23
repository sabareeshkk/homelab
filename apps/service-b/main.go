package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/jackc/pgx/v5"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetricgrpc"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/metric"
	sdkmetric "go.opentelemetry.io/otel/sdk/metric"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.17.0"
	"go.opentelemetry.io/otel/trace"
)

var (
	tracer      trace.Tracer
	db          *pgx.Conn
	dataCounter metric.Int64Counter
)

func initConn() (func(context.Context) error, error) {
	ctx := context.Background()

	res, err := resource.New(ctx,
		resource.WithAttributes(
			semconv.ServiceNameKey.String("service-b"),
		),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create resource: %w", err)
	}

	otelAgentAddr, ok := os.LookupEnv("OTEL_EXPORTER_OTLP_ENDPOINT")
	if !ok {
		otelAgentAddr = "otel-collector.monitoring.svc.cluster.local:4317"
	}

	// Trace Exporter
	traceExporter, err := otlptracegrpc.New(ctx,
		otlptracegrpc.WithInsecure(),
		otlptracegrpc.WithEndpoint(otelAgentAddr),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create trace exporter: %w", err)
	}

	bsp := sdktrace.NewBatchSpanProcessor(traceExporter)
	tracerProvider := sdktrace.NewTracerProvider(
		sdktrace.WithSampler(sdktrace.AlwaysSample()),
		sdktrace.WithResource(res),
		sdktrace.WithSpanProcessor(bsp),
	)
	otel.SetTracerProvider(tracerProvider)

	// Metric Exporter
	metricExporter, err := otlpmetricgrpc.New(ctx,
		otlpmetricgrpc.WithInsecure(),
		otlpmetricgrpc.WithEndpoint(otelAgentAddr),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create metric exporter: %w", err)
	}

	meterProvider := sdkmetric.NewMeterProvider(
		sdkmetric.WithResource(res),
		sdkmetric.WithReader(sdkmetric.NewPeriodicReader(metricExporter)),
	)
	otel.SetMeterProvider(meterProvider)

	tracer = otel.Tracer("service-b")
	meter := otel.Meter("service-b")
	dataCounter, _ = meter.Int64Counter("service_b_data_access_total", metric.WithDescription("Total number of data accesses in Service B"))

	return tracerProvider.Shutdown, nil
}

func initDB() error {
	connStr := os.Getenv("DATABASE_URL")
	if connStr == "" {
		connStr = "postgres://user:password@postgres.default.svc.cluster.local:5432/dbname"
	}

	var err error
	db, err = pgx.Connect(context.Background(), connStr)
	if err != nil {
		return fmt.Errorf("unable to connect to database: %w", err)
	}

	// Create a dummy table if it doesn't exist
	_, err = db.Exec(context.Background(), "CREATE TABLE IF NOT EXISTS system_info (info TEXT)")
	if err != nil {
		log.Printf("could not create table: %v", err)
	}

	// Seed data if empty
	var count int
	_ = db.QueryRow(context.Background(), "SELECT count(*) FROM system_info").Scan(&count)
	if count == 0 {
		_, _ = db.Exec(context.Background(), "INSERT INTO system_info (info) VALUES ('Homelab data initialized at ' || now())")
	}

	return nil
}

func main() {
	shutdown, err := initConn()
	if err != nil {
		log.Fatalf("failed to initialize OTel: %v", err)
	}
	defer shutdown(context.Background())

	if err := initDB(); err != nil {
		log.Printf("Warning: Database not initialized: %v", err)
	} else {
		defer db.Close(context.Background())
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/data", func(w http.ResponseWriter, r *http.Request) {
		ctx := r.Context()
		dataCounter.Add(ctx, 1)

		_, span := tracer.Start(ctx, "QueryDatabase", trace.WithAttributes(attribute.String("db.system", "postgresql")))
		defer span.End()

		log.Printf("Querying database...")

		var info string
		err := db.QueryRow(ctx, "SELECT info FROM system_info LIMIT 1").Scan(&info)
		if err != nil {
			info = "No database connection, returning local mock data"
			span.RecordError(err)
		}

		fmt.Fprintf(w, "Service B Logic: %s (Time: %s)", info, time.Now().Format(time.RFC3339))
	})

	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	server := &http.Server{
		Addr:    ":8081",
		Handler: otelhttp.NewHandler(mux, "http-server"),
	}

	log.Println("Service B listening on :8081...")
	if err := server.ListenAndServe(); err != nil {
		log.Fatalf("server failed: %v", err)
	}
}
