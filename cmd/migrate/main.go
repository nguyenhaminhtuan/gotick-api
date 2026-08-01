package main

import (
	"flag"
	"gotick/db"
	"gotick/internal/config"
	"log"
	"os"

	"github.com/amacneil/dbmate/v2/pkg/dbmate"
	_ "github.com/amacneil/dbmate/v2/pkg/driver/postgres"
)

func main() {
	flag.Parse()
	command := flag.Arg(0)

	config, err := config.LoadDBConfig()
	if err != nil {
		log.Fatalf("failed to load DB config: %v", err)
	}

	provider := dbmate.New(config.URL())
	provider.FS = db.Migrations
	provider.MigrationsDir = []string{"migrations"}
	provider.SchemaFile = "db/schema.sql"
	provider.AutoDumpSchema = os.Getenv("MIGRATE_NO_DUMP_SCHEMA") == ""

	switch command {
	case "up":
		log.Println("Applying migration")
		if err := provider.CreateAndMigrate(); err != nil {
			log.Fatalf("up: %v", err)

		}
	case "down":
		log.Println("Rolling back migration")
		if err := provider.Rollback(); err != nil {
			log.Fatalf("down: %v", err)
		}
	case "status":
		if _, err := provider.Status(false); err != nil {
			log.Fatalf("status: %v", err)
		}
	default:
		log.Fatalf("invalid command: %s", command)
	}
}
