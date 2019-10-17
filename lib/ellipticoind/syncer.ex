defmodule Ellipticoind.Syncer do
  require Logger
  alias Ellipticoind.Miner
  alias Ellipticoind.Models.Block
  alias Ellipticoind.Repo
  use GenServer

  @fast_sync_batch_size 10
  @ellipticoin_client Application.get_env(:ellipticoind, :ellipticoin_client)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_init_arg) do
    SystemContracts.deploy()
    fast_sync()

    {:ok, nil}
  end

  def fast_sync() do
    GenServer.cast(__MODULE__, {:fast_sync})
  end

  def get_next_block() do
    GenServer.cast(__MODULE__, {:get_next_block})
  end

  def handle_cast({:fast_sync}, state) do
    blocks = @ellipticoin_client.get_blocks()
    total_blocks = length(blocks)
    blocks_stream = Stream.map(Enum.reverse(blocks), &(&1))
    Enum.map(Stream.chunk_every(blocks_stream, @fast_sync_batch_size), fn blocks ->
      start_block_number = List.first(blocks).number
      end_block_number = List.last(blocks).number
      percentage_complete = round(end_block_number*100/total_blocks)

      blocks |> Enum.map(&Block.process_transactions/1)
      blocks |> Enum.map(&Repo.insert/1)
      Logger.info("Applied blocks #{start_block_number} to #{end_block_number} (fast-sync #{percentage_complete}% complete)")
    end)
    IO.puts "get next block"
    get_next_block()

    {:noreply, state}
  end


  def handle_cast({:get_next_block}, state) do
    IO.puts "getting next block: ##{Block.next_block_number()}"
    case @ellipticoin_client.get_block(Block.next_block_number()) do
      nil -> Miner.start_link(%{})
      block ->
        Block.process_transactions(block)
        Repo.insert(block)
        get_next_block()
    end

    {:noreply, state}
  end

end
