defmodule BackendWeb.UserChannel do
  use Phoenix.Channel

  @impl true
  def join("user:" <> user_id, _params, socket) do
    # Subscribe to PubSub for this user
    Phoenix.PubSub.subscribe(Backend.PubSub, "user:#{user_id}")

    {:ok, assign(socket, :user_id, user_id)}
  end

  @impl true
  def handle_info({:order_filled, order}, socket) do
    push(socket, "order_filled", format_order(order))
    {:noreply, socket}
  end

  @impl true
  def handle_info({:order_cancelled, order}, socket) do
    push(socket, "order_cancelled", format_order(order))
    {:noreply, socket}
  end

  @impl true
  def handle_info({:order_expired, order}, socket) do
    push(socket, "order_expired", format_order(order))
    {:noreply, socket}
  end

  defp format_order(order) do
    %{
      id: order.id,
      side: order.side,
      price: Decimal.to_string(order.price),
      quantity: order.quantity,
      remaining_quantity: order.remaining_quantity,
      status: order.status,
      company_id: order.company_id
    }
  end
end
