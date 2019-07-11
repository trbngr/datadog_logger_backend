defmodule DatadogLoggerBackend do
  alias DatadogLoggerBackend.Config

  @behaviour :gen_event

  @impl true
  def init(_) do
    if user = Process.whereis(:user) do
      Process.group_leader(self(), user)

      options =
        Application.get_env(:logger, :datadog,
          level: :debug,
          service: :elixir
        )

      {:ok, configure(options)}
    else
      {:error, :ignore}
    end
  end

  @impl true
  def handle_call({:configure, options}, _state),
    do: {:ok, :ok, configure(options)}

  @impl true
  def handle_event({level, _gl, log}, state) do
    state =
      if Logger.compare_levels(level, state.level) != :lt do
        case send_log(level, log, state) do
          :ok ->
            state

          _ ->
            system_opts = Application.get_env(:logger, :datadog) || []
            configure(system_opts)
        end
      end

    {:ok, state}
  end

  def handle_event(:flush, state), do: {:ok, state}

  defp send_log(lvl, {Logger, msg, _ts, meta}, state) do
    {:ok, hostname} = :inet.gethostname()

    metadata = normalize(meta)

    message =
      case msg do
        message when is_list(message) -> IO.iodata_to_binary(message)
        message -> message
      end

    values = %{
      "message" => message,
      "level" => lvl,
      "source" => "elixir",
      "host" => List.to_string(hostname),
      "service" => state.service
    }

    data =
      values
      |> Map.merge(metadata)
      |> Jason.encode_to_iodata!()

    :poolboy.transaction(:datadog_sender, fn pid ->
      DatadogLoggerBackend.Sender.send(pid, data)
    end)
  end

  defp configure(opts) do
    Enum.into(opts, %{})
  end

  def normalize(list) when is_list(list) do
    if Keyword.keyword?(list) do
      list
      |> Enum.into(%{})
      |> normalize()
    else
      Enum.map(list, &normalize/1)
    end
  end

  def normalize(%{__struct__: type} = map) do
    map
    |> Map.from_struct()
    |> Map.merge(%{type: type})
    |> normalize()
  end

  def normalize(map) when is_map(map),
    do: Enum.reduce(map, %{}, fn {key, value}, acc -> Map.put(acc, key, normalize(value)) end)

  def normalize(string) when is_binary(string), do: string

  def normalize(other), do: inspect(other)
end
