defmodule DatadogLoggerBackend.Sender do
  use Connection

  def start_link(opts) do
    Connection.start_link(__MODULE__, opts)
  end

  def send(conn, data), do: Connection.call(conn, {:send, data})

  def recv(conn, bytes, timeout \\ 3000) do
    Connection.call(conn, {:recv, bytes, timeout})
  end

  def close(conn), do: Connection.call(conn, :close)

  def init(opts) do
    state = Enum.into(opts, %{sock: nil})
    {:connect, :init, state}
  end

  def connect(_, state) do
    %{sock: nil, host: host, port: port, opts: opts, timeout: timeout} = state

    opts = [active: false] ++ opts
    result = :gen_tcp.connect(host, port, opts, timeout)

    case result do
      {:ok, sock} ->
        IO.puts("Connected to #{host}")
        {:ok, %{state | sock: sock}}

      {:error, reason} ->
        IO.puts("Failed to connect to #{host}: #{reason}")
        {:connect, :reconnect, state}
    end
  end

  def disconnect(info, %{sock: sock, host: host} = s) do
    :ok = :gen_tcp.close(sock)

    case info do
      {:close, from} ->
        Connection.reply(from, :ok)

      {:error, :closed} ->
        IO.puts("Connection to #{host} closed")

      {:error, reason} ->
        reason = :inet.format_error(reason)
        IO.puts("Connection error: #{reason}")
    end

    {:connect, :reconnect, %{s | sock: nil}}
  end

  def handle_call(_, _, %{sock: nil} = s) do
    {:reply, {:error, :closed}, s}
  end

  def handle_call({:send, data}, _, %{sock: sock, api_token: api_token} = s) do
    case :gen_tcp.send(sock, [api_token, " ", data, ?\r, ?\n]) do
      :ok ->
        {:reply, :ok, s}

      {:error, _} = error ->
        {:disconnect, error, error, s}
    end
  end

  def handle_call({:recv, bytes, timeout}, _, %{sock: sock} = s) do
    case :gen_tcp.recv(sock, bytes, timeout) do
      {:ok, _} = ok ->
        {:reply, ok, s}

      {:error, :timeout} = timeout ->
        {:reply, timeout, s}

      {:error, _} = error ->
        {:disconnect, error, error, s}
    end
  end

  def handle_call(:close, from, s) do
    {:disconnect, {:close, from}, s}
  end
end
