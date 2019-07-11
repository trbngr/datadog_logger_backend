defmodule DatadogLoggerBackendTest do
  use ExUnit.Case
  require Logger
  doctest DatadogLoggerBackend

  test "greets the world" do
    Logger.info("yo from the backend", map: %{thing: :a})
  end
end
