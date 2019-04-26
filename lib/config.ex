defmodule Config do
  @hashes_per_millisecond 1000

  def hashfactor_target(),
    do: Application.fetch_env!(:node, :mining_target_time) * @hashes_per_millisecond

  def private_key(), do: Application.fetch_env!(:node, :private_key)

  def transaction_processing_time(),
    do: Application.fetch_env!(:node, :transaction_processing_time)

  def redis_url(), do: Application.fetch_env!(:node, :redis_url)

  def public_key(),
    do:
      private_key()
      |> Crypto.private_key_to_public_key()

  def p2p_transport() do
    transport = Application.fetch_env!(:node, :p2p_transport)
    options = Application.fetch_env!(:node, transport)

    {transport, Enum.into(options, %{})}
  end

  def cowboy() do
    {Plug.Cowboy,
      scheme: :http,
      plug: Router,
      options: [
        dispatch: Cowboy.dispatch(),
        port: Application.fetch_env!(:node, :port)
      ]}
  end
end
