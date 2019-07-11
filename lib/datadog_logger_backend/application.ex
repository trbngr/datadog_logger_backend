defmodule DatadogLoggerBackend.Application do
  use Application

  alias DatadogLoggerBackend.Config

  defp poolboy_config({workers, max_overflow_workers}) do
    [
      {:name, {:local, :datadog_sender}},
      {:worker_module, DatadogLoggerBackend.Sender},
      {:size, workers},
      {:max_overflow, max_overflow_workers}
    ]
  end

  def start(_type, args) do
    {workers, sender_config} = Config.parsed(args)

    children = [
      :poolboy.child_spec(:worker, poolboy_config(workers), sender_config)
    ]

    opts = [strategy: :one_for_one, name: DatadogLoggerBackend.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
