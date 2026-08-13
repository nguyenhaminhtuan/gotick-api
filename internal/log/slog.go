package log

import (
	"fmt"
	"io"
	"log/slog"
	"os"
	"time"

	"gotick/internal/config"

	"github.com/rs/zerolog"
	slogctx "github.com/veqryn/slog-context"
)

const (
	FormatJSON = "json"
	FormatText = "text"
)

func New(cfg config.LogConfig) (*slog.Logger, error) {
	zl, err := newZerolog(cfg)
	if err != nil {
		return nil, err
	}

	return slog.New(slogctx.NewHandler(zerolog.NewSlogHandler(zl), nil)), nil
}

func newZerolog(cfg config.LogConfig) (zerolog.Logger, error) {
	level, err := zerolog.ParseLevel(cfg.Level)
	if err != nil {
		return zerolog.Nop(), fmt.Errorf("parse log level %q: %w", cfg.Level, err)
	}

	if cfg.EnableCloudLogging {
		useCloudLoggingFields()
	}

	var w io.Writer
	switch cfg.Format {
	case FormatJSON:
		w = os.Stderr
	case FormatText:
		w = zerolog.ConsoleWriter{Out: os.Stderr, TimeFormat: time.TimeOnly}
	default:
		return zerolog.Nop(), fmt.Errorf("unknown log format %q, want %q or %q", cfg.Format, FormatJSON, FormatText)
	}

	zerolog.SetGlobalLevel(zerolog.TraceLevel)
	return zerolog.New(w).Level(level).With().Timestamp().Logger(), nil
}
