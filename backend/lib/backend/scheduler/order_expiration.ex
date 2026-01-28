defmodule Backend.Scheduler.OrderExpiration do
  @moduledoc """
  GenServer that periodically checks for and expires old orders.
  """

  use GenServer

  alias Backend.Marketplace
  alias Backend.Audit

  @check_interval :timer.seconds(30)

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    schedule_check()
    {:ok, state}
  end

  @impl true
  def handle_info(:check_expirations, state) do
    expire_orders()
    schedule_check()
    {:noreply, state}
  end

  defp schedule_check do
    Process.send_after(self(), :check_expirations, @check_interval)
  end

  defp expire_orders do
    expired_orders = Marketplace.get_expired_orders()

    Enum.each(expired_orders, fn order ->
      case Marketplace.expire_order(order) do
        {:ok, expired_order} ->
          Audit.log("order_expired", "order", order.id, order.user_id, %{
            original_quantity: order.quantity,
            remaining_quantity: order.remaining_quantity
          })

          # Broadcast expiration
          Phoenix.PubSub.broadcast(
            Backend.PubSub,
            "company:#{order.company_id}",
            {:order_book_update, Marketplace.get_order_book(order.company_id)}
          )

          Phoenix.PubSub.broadcast(
            Backend.PubSub,
            "user:#{order.user_id}",
            {:order_expired, expired_order}
          )

        {:error, _reason} ->
          :ok
      end
    end)
  end
end
