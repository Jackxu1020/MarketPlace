defmodule Backend.Audit do
  @moduledoc """
  Simple append-only audit logging.
  """

  import Ecto.Query
  alias Backend.Repo
  alias Backend.Audit.AuditLog

  def log(action, entity_type, entity_id, user_id \\ nil, metadata \\ %{}) do
    %AuditLog{}
    |> AuditLog.changeset(%{
      action: action,
      entity_type: entity_type,
      entity_id: entity_id,
      user_id: user_id,
      metadata: metadata
    })
    |> Repo.insert()
  end

  def list_logs(limit \\ 100) do
    from(l in AuditLog, order_by: [desc: l.inserted_at], limit: ^limit)
    |> Repo.all()
  end

  def list_logs_for_entity(entity_type, entity_id) do
    from(l in AuditLog,
      where: l.entity_type == ^entity_type and l.entity_id == ^entity_id,
      order_by: [desc: l.inserted_at]
    )
    |> Repo.all()
  end
end
