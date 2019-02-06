defmodule Models.BlockTest do
  import Blacksmith.Factory
  import Test.Utils

  alias Blacksmith.Models.{Block, Transaction, Contract}
  use ExUnit.Case, async: true
  use NamedAccounts
  use OK.Pipe

  setup do
    checkout_repo()
    insert_contracts()
    Redis.reset()

    on_exit(fn ->
      Redis.reset()
    end)
  end

  describe "Block.forge/0" do
    test "it creates a new block" do
      genisis_block = insert(:block)

      set_balances(%{
        @alice => 100,
        @bob => 100
      })

      Transaction.post(%{
        contract_address: <<0::256>>,
        contract_name: :BaseToken,
        function: :transfer,
        arguments: [@bob, 50],
        sender: @alice
      })

      {:ok, block} =
        Block.forge(%{
          winner: <<0::256>>,
          block_number: 1
        })

      assert block.number == 1
      assert block.parent == genisis_block

      assert Base.encode16(block.changeset_hash) ==
               "0212F77EA6539811CCBD42064B8D0399DAF114F06B4C36C56AE0B26E36DDCFEE"

      assert Base.encode16(block.block_hash) ==
               "7F50AB9AD65D94D5E626237B6E4D986A62D7C1061EF6805676987F7A3B793D3C"
    end
  end
end