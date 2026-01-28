defmodule BackendWeb.UserSocket do
  use Phoenix.Socket

  channel "company:*", BackendWeb.CompanyChannel
  channel "user:*", BackendWeb.UserChannel

  @impl true
  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  @impl true
  def id(_socket), do: nil
end
