defmodule Node.Models.Transaction do
  use Ecto.Schema
  alias Node.Models.{Contract, Block}
  alias Node.Ecto.Types
  alias Node.Repo
  import Ecto.Changeset

  schema "transactions" do
    field(:block_hash, :binary)
    field(:contract_name, Types.Atom)
    field(:contract_address, :binary)
    field(:function, Types.Atom)
    field(:arguments, Types.Cbor)
    field(:sender, :binary)
    field(:nonce, :integer)
    field(:return_code, :integer)
    field(:return_value, Types.Cbor)
    field(:signature, :binary)

    timestamps()
  end

  @doc false
  def changeset(transaction, attrs) do
    # IO.inspect attrs
    transaction
    |> cast(attrs, [
      :contract_address,
      :contract_name,
      :return_code,
      :return_value,
      :function,
      :arguments
    ])
    |> validate_required([
      :contract_address,
      :contract_name,
      :return_code,
      :function,
      :arguments
    ])
  end

  def as_map(attributes) do
    attributes
      |> Map.take([
        :block_hash,
        :sender,
        :function,
        :contract_name,
        :contract_address,
        :arguments,
        :return_value,
        :return_code,
      ])
  end

  def with_code(attributes) do
    code = Repo.get_by(Contract, name: attributes.contract_name)
           |> Map.get(:code)

    attributes
      |> Map.merge(%{
        contract_address: <<0::256>>,
        code: code,
      })
  end

  def sign(transaction, private_key) do
    sender = Crypto.private_key_to_public_key(private_key)
    signature = Crypto.sign(as_map(transaction), private_key)

    transaction
      |> Map.put(:sender, sender)
      |> Map.put(:signature, signature)
  end

  def post(parameters) do
    with_code(parameters)
      |> TransactionPool.add()
  end
end