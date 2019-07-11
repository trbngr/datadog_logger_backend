require Logger
Logger.add_backend(DatadogLoggerBackend)

ExUnit.start()
