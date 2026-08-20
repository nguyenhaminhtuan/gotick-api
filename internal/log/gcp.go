package log

import (
	"time"

	"github.com/rs/zerolog"
)

// https://cloud.google.com/logging/docs/structured-logging
func useCloudLoggingFields() {
	zerolog.LevelFieldName = "severity"
	zerolog.MessageFieldName = "message"
	zerolog.TimestampFieldName = "timestamp"
	zerolog.TimeFieldFormat = time.RFC3339Nano
	zerolog.LevelFieldMarshalFunc = cloudLoggingSeverity
}

func cloudLoggingSeverity(l zerolog.Level) string {
	switch l {
	case zerolog.TraceLevel, zerolog.DebugLevel:
		return "DEBUG"
	case zerolog.InfoLevel:
		return "INFO"
	case zerolog.WarnLevel:
		return "WARNING"
	case zerolog.ErrorLevel:
		return "ERROR"
	case zerolog.FatalLevel:
		return "CRITICAL"
	case zerolog.PanicLevel:
		return "ALERT"
	case zerolog.NoLevel, zerolog.Disabled:
		return "DEFAULT"
	default:
		return "DEFAULT"
	}
}
