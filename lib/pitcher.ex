defmodule Logger.Backend.Pitcher do
  use GenEvent

  require Logger

  defstruct name: nil,
            dispatcher: nil,
            url: nil,
            method: nil,
            headers: nil,
            opts: nil,
            level: nil,
            format: nil,
            metadata: nil,
            context: nil,
            metadata_filter: nil

  @default_format "[$level] $message\n"

  @default_config [
    dispatcher: Logger.Backend.Pitcher.Dispatcher.HTTPoison,
    url: '',
    method: :post,
    headers: [],
    opts: [],
    level: :debug,
    metadata: [],
    format: Logger.Formatter.compile(@default_format),
    metadata_filter: nil
  ]

  def init({__MODULE__, name}) do
    {:ok, init_config(name, [])}
  end

  def handle_call({:configure, opts}, %{name: name} = state) do
    {:ok, :ok, init_config(name, opts, state)}
  end

  def handle_call(:dispatcher, %{dispatcher: dispatcher} = state) do
    {:ok, {:ok, dispatcher}, state}
  end

  def handle_call(:destroy, state) do
    {:ok, :ok, %{state | context: nil}}
  end

  def handle_event(
        {level, _gl, {Logger, msg, ts, md}},
        %{level: min_level, metadata_filter: metadata_filter} = state
      ) do
    state =
      if (is_nil(min_level) or Logger.compare_levels(level, min_level) != :lt) and
           has_metadata?(md, metadata_filter) do
        init_dispatcher_and_log_msg(state, level, msg, ts, md, true)
      else
        state
      end

    {:ok, state}
  end

  def handle_event(:flush, state) do
    {:ok, state}
  end

  defp log_msg(level, msg, ts, md, state) do
    body = format_msg(level, msg, ts, md, state)
    state.dispatcher.send(state.context, body)
    state
  end

  defp format_msg(level, msg, ts, md, %{format: format, metadata: keys}) do
    Logger.Formatter.format(format, level, msg, ts, filter_keys(md, keys))
  end

  def init_dispatcher_and_log_msg(%{context: nil} = state, level, msg, ts, md, true) do
    init_dispatcher(state) |> init_dispatcher_and_log_msg(level, msg, ts, md, false)
  end

  def init_dispatcher_and_log_msg(%{context: nil} = state, _level, _msg, _ts, _md, _retry) do
    Logger.error("pitcher is not initialised")
    state
  end

  def init_dispatcher_and_log_msg(state, level, msg, ts, md, _retry),
    do: log_msg(level, msg, ts, md, state)

  def has_metadata?(md, [{key, val} | rest]) do
    case Keyword.fetch(md, key) do
      {:ok, ^val} ->
        has_metadata?(md, rest)

      _ ->
        false
    end
  end

  def has_metadata?(_md, _), do: true

  defp filter_keys(meta, keys) do
    meta
    |> Enum.into(%{})
    |> Map.take(keys)
    |> Map.to_list()
  end

  defp init_config(name, opts) do
    init_config(name, opts, %__MODULE__{})
  end

  defp init_config(name, opts, state) do
    data = Keyword.merge(Application.get_env(:logger, name, []), opts)

    Application.put_env(:logger, name, data)

    data =
      @default_config
      |> Keyword.merge(data)
      |> compile_format()

    new_state = Enum.into(data, %{})
    Map.merge(state, new_state)
  end

  def init_dispatcher(
        %{dispatcher: dispatcher, method: method, url: url, headers: headers, opts: opts} = state
      ) do
    case dispatcher.init(method, url, headers, opts) do
      {:ok, context} ->
        %{state | context: context}

      {:error, reason} ->
        Logger.error("error creating pitcher context: #{inspect(reason)}")
        %{state | context: nil}
    end
  end

  def compile_format(opts) do
    case Keyword.get(opts, :format, @default_format) do
      format when is_binary(format) ->
        Keyword.put(opts, :format, Logger.Formatter.compile(format))

      _ ->
        opts
    end
  end
end
