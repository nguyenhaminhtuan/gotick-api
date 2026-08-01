package config

import (
	"fmt"
	"net"
	"net/url"
	"strings"
	"time"

	"github.com/caarlos0/env/v11"
	_ "github.com/joho/godotenv/autoload"
)

type Config struct {
	Env            string   `env:"ENV" envDefault:"development"`
	Host           string   `env:"HOST" envDefault:"0.0.0.0"`
	Port           int      `env:"PORT" envDefault:"8080"`
	AllowedOrigins []string `env:"ALLOWED_ORIGINS" envSeparator:"," envDefault:"*"`

	ServerConfig ServerConfig `envPrefix:"SERVER_"`
	DBConfig     DBConfig     `envPrefix:"DB_"`
	LogConfig    LogConfig    `envPrefix:"LOG_"`
}

type ServerConfig struct {
	IdleTimeout  time.Duration `env:"IDLE_TIMEOUT" envDefault:"1m"`
	ReadTimeout  time.Duration `env:"READ_TIMEOUT" envDefault:"10s"`
	WriteTimeout time.Duration `env:"WRITE_TIMEOUT" envDefault:"30s"`

	ShutdownGrace time.Duration `env:"SHUTDOWN_GRACE" envDefault:"5s"`
}

func (c ServerConfig) ShutdownTimeout() time.Duration {
	return c.WriteTimeout + c.ShutdownGrace
}

type LogConfig struct {
	Level  string `env:"LEVEL" envDefault:"info"`
	Format string `env:"FORMAT" envDefault:"json"`

	EnableCloudLogging bool `env:"ENABLE_CLOUD_LOGGING" envDefault:"false"`
}

type DBConfig struct {
	Host     string `env:"HOST,required"`
	Port     string `env:"PORT" envDefault:"5432"`
	User     string `env:"USER,required"`
	Password string `env:"PASSWORD,required"`
	Name     string `env:"NAME,required"`
	SSLMode  string `env:"SSL_MODE" envDefault:"require"`

	StatementTimeout time.Duration `env:"STATEMENT_TIMEOUT" envDefault:"30s"`

	MinConns int32 `env:"MIN_CONNS" envDefault:"5"`
	MaxConns int32 `env:"MAX_CONNS" envDefault:"20"`

	ShowSQL            bool          `env:"SHOW_SQL" envDefault:"false"`
	SlowQueryThreshold time.Duration `env:"SLOW_QUERY_THRESHOLD" envDefault:"2s"`
}

func Load() (*Config, error) {
	cfg := &Config{}
	if err := env.Parse(cfg); err != nil {
		return nil, fmt.Errorf("invalid config: %w", err)
	}

	return cfg, nil
}

func LoadDBConfig() (*DBConfig, error) {
	cfg := &DBConfig{}
	if err := env.ParseWithOptions(cfg, env.Options{Prefix: "DB_"}); err != nil {
		return nil, fmt.Errorf("invalid database config: %w", err)
	}
	return cfg, nil
}

func (c *Config) IsLocal() bool {
	return c.Env == "local"
}

func (c *Config) IsProd() bool {
	return c.Env == "production"
}

func (c *DBConfig) DSN() string {
	timeoutOption := fmt.Sprintf("-c statement_timeout=%d", c.StatementTimeout/time.Millisecond)
	return fmt.Sprintf(
		"user='%s' password='%s' host='%s' port=%s dbname='%s' sslmode='%s' options='%s'",
		c.User, c.Password, c.Host, c.Port, c.Name, c.SSLMode, timeoutOption,
	)
}

func (c *DBConfig) URL() *url.URL {
	u := url.URL{
		Scheme: "postgres",
		User:   url.UserPassword(c.User, c.Password),
		Path:   "/" + c.Name,
	}

	q := url.Values{}
	q.Set("sslmode", c.SSLMode)

	if strings.HasPrefix(c.Host, "/") {
		// Unix socket (eg Cloud SQL: /cloudsql/proj:region:inst)
		q.Set("host", c.Host)
	} else {
		u.Host = net.JoinHostPort(c.Host, c.Port)
	}

	u.RawQuery = q.Encode()
	return &u
}
