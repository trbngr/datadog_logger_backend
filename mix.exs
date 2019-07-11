defmodule DatadogLoggerBackend.MixProject do
  use Mix.Project

  def project do
    [
      app: :datadog_logger_backend,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod:
        {DatadogLoggerBackend.Application,
         [
           workers: 2,
           timeout: :timer.seconds(5),
           host: "intake.logs.datadoghq.com",
           port: 10514,
           opts: [],
           level: :debug,
           api_token: {System, "DATADOG_API_KEY"}
         ]}
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.1"},
      {:poolboy, "~> 1.5"},
      {:connection, "~> 1.0"}
    ]
  end
end
