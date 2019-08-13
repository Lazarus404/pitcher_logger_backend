defmodule Logger.Backend.Pitcher.Test do
  use ExUnit.Case, async: false
  require Logger

  @backend {Logger.Backend.Pitcher, :test}
  Logger.add_backend(@backend)

  setup do
    config(
      dispatcher: Logger.Backend.Pitcher.Test.Dispatcher,
      method: :post,
      url: 'http://localhost/log',
      format: "[$level] $message\n",
      metadata_filter: []
    )

    on_exit(fn ->
      dispatcher().destroy()
      destroy()
    end)

    :ok
  end

  test "level defaults to `:debug`" do
    assert Logger.level() == :debug
  end

  test "does not log debug when level set to info" do
    refute dispatcher().exists?()
    config(level: :info)
    Logger.debug("should not appear in logs")
    refute dispatcher().exists?()
  end

  test "does log when level is above or equal minimum Logger level" do
    refute dispatcher().exists?()
    config(level: :info)
    Logger.warn("should appear in logs")
    assert log_contains?("[warn] should appear in logs\n")
  end

  test "configures formatting" do
    refute dispatcher().exists?()
    config(format: "$message ($level)\n")
    Logger.info("formatted string")
    assert log_contains?("formatted string (info)\n")
  end

  test "metadata not logged if not set" do
    refute dispatcher().exists?()
    config(format: "$metadata$message\n", metadata: [:one, :two])
    Logger.info("no meta")
    assert log_contains?("no meta\n")
  end

  test "metadata logged if configured" do
    refute dispatcher().exists?()
    config(format: "$metadata$message\n", metadata: [:one, :two])
    Logger.metadata(one: 3)
    Logger.metadata(two: 4)
    Logger.metadata(one: 5)
    Logger.info("metadata logged")
    assert log_contains?("one=5 two=4 metadata logged\n")
  end

  test "metadata_filter is configurable" do
    refute dispatcher().exists?()
    config(format: "$message\n", metadata_filter: [test: true])
    Logger.info("logged message", test: true)
    assert log_contains?("logged message\n")
  end

  test "metadata_filter only shows messages with matched meta" do
    refute dispatcher().exists?()
    config(format: "$message\n", metadata_filter: [key: "bob"])
    Logger.info("should log", key: "bob")
    Logger.info("should not log")
    Logger.info("also should not log", key: "ted")
    Logger.info("should not log, either", name: "bob")
    Logger.info("should log, too", key: "bob")
    assert log_contains?("should log\nshould log, too\n")
  end

  test "filtering messages with multiple matched meta" do
    refute dispatcher().exists?()
    config(format: "$message\n", metadata_filter: [name: "bob", age: 42])
    Logger.info("should not log without complete match", key: "bob")
    Logger.info("should not log")
    Logger.info("should log, either", age: 42)
    Logger.info("should log", name: "bob", age: 42)
    Logger.info("should not log", key: "invalid")
    Logger.info("neither should this log", age: 12)
    assert log_contains?("should log\n")
  end

  defp config(opts) do
    Logger.configure_backend(@backend, opts)
  end

  defp dispatcher() do
    {:ok, dispatcher} = GenEvent.call(Logger, @backend, :dispatcher)
    dispatcher
  end

  defp log_contains?(val) do
    String.contains?(dispatcher().get(), val)
  end

  defp destroy() do
    :ok = GenEvent.call(Logger, @backend, :destroy)
  end

  defmodule Dispatcher do
    alias Logger.Backend.Pitcher.Dispatcher.Context, as: Ctx

    @logfile "test.log"

    def init(_method, _url, _opts \\ [], _header \\ []) do
      {:ok, h} = File.open(@logfile, [:write])
      {:ok, %Ctx{method: h}}
    end

    def send(ctx, body) do
      IO.write(ctx.method, body)
    end

    def exists?() do
      File.exists?(@logfile)
    end

    def get() do
      if exists?() do
        File.read!(@logfile)
      end
    end

    def destroy() do
      if exists?() do
        File.rm!(@logfile)
      end
    end
  end
end
