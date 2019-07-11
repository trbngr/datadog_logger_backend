defmodule DatadogLoggerBackend.Config do
  def parsed(args) do
    supplied_config = Application.get_env(:logger, :datadog, [])

    conf =
      args
      |> Keyword.merge(supplied_config)
      |> Enum.map(&normalize/1)

    {conf[:workers], Keyword.delete(conf, :workers)}
  end

  defp normalize({key, {System, var, default}}), do: {key, System.get_env(var) || default}
  defp normalize({key, {System, var}}), do: {key, System.get_env(var)}
  defp normalize({:host, value}), do: {:host, to_charlist(value)}
  defp normalize({key, value}), do: {key, value}
end
