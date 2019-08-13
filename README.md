# Pitcher

Pitcher is an [Elixir Logger](https://hexdocs.pm/logger/Logger.html) backend used to send logs to a custom REST endpoint.

## Options

**url**: The URL, including protocol, domain, port and path to send the logs
**method**: An atom used to denote the method to use (:post, :put, :get etc.)
**opts**: A list of options as per the [HTTPoison](https://hexdocs.pm/httpoison/HTTPoison.html) dependency
**headers**: A list of headers as per the [HTTPoison](https://hexdocs.pm/httpoison/HTTPoison.html) dependency
**format**: The logging format of the message. (defaults to `[$level] $message\n`)
**level**: The minimum level to log. (defaults to `:debug`)
**metadata**: Additional fields to be sent to the logs. These are merged with the default metadata
**metadata_filter**: Sends only those metadata fields that are in the filter (all are sent if filter is not set)

## Installation

Simply add to your mix.exs file as a dependency:

```elixir
def deps do
  [{:pitcher_logger_backend, "~> 0.0.1"}]
end
```
Then run mix deps.get to install it.

## Configuration

```elixir
config :logger,
  backends: [{Logger.Backend.Pitcher, :my_error_log}, :console]

config :logger, :my_error_log,
  host: "https://mydomain.com/logs",
  method: :put,
  level: :error,
  format: "[$level] $message\n"
```