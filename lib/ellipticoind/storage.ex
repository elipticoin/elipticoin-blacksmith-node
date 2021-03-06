defmodule Ellipticoind.Storage do
  alias Ellipticoind.BlockIndex
  import Binary
  @prefix "storage"

  def write_changeset(changeset, block_number) do
    for {key, value} <- changeset do
      set(block_number, key, value)
    end
  end

  def get_value(address, contract_name, key) do
    memory = get(address, contract_name, key)

    if memory == [] do
      nil
    else
      Cbor.decode!(memory)
    end
  end

  def set(block_number, address, contract_name, key, value) do
    set(block_number, to_key(address, contract_name, key), value)
  end

  def get(address, contract_name, key), do: get(to_key(address, contract_name, key))

  def to_key(address, contract_name, key),
    do: ((address <> Atom.to_string(contract_name)) |> pad_trailing(64)) <> key

  def get(key) do
    if block_number = BlockIndex.get_latest(@prefix, key) do
      RocksDB.get(block_number, key)
    else
      []
    end
  end

  def set(block_number, key, value) do
    BlockIndex.add(@prefix, key, block_number)
    RocksDB.put(block_number, key, value)
  end
end
