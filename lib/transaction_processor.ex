defmodule TransactionProccessor do
  use GenServer
  alias Redis.PubSub

  @crate "transaction_processor"
  @channel "transaction_processor"

  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  def init(state) do
    {:ok, redis} = Redix.start_link()

    Port.open({:spawn_executable, path_to_executable()},
      args: ["redis://127.0.0.1/"]
    )

    {:ok,
     Map.merge(state, %{
       redis => redis
     })}
  end

  def done() do
    GenServer.cast(__MODULE__, {:done})
  end

  def proccess_transactions(duration) do
    GenServer.cast(__MODULE__, {:proccess_transactions, duration})
  end

  def wait_until_done() do
    PubSub.subscribe(@channel, self())

    receive do
      {:pubsub, "transaction_processor", "done"} -> nil
    end
  end

  def handle_cast({:proccess_transactions, duration}, state) do
    Redis.publish(@channel, ["proccess_transactions", duration])
    {:noreply, state}
  end

  def handle_cast({:done}, state) do
    IO.inspect("done processing!")
    {:noreply, state}
  end

  def handle_info({_port, {:data, message}}, state) do
    IO.write(message)
    {:noreply, state}
  end

  def path_to_executable() do
    Path.expand("../priv/native/#{@crate}", __DIR__)
  end

  def mode() do
    if(Mix.env() == :prod, do: :release, else: :debug)
  end
end