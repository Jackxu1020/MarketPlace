defmodule Backend.Audit.AuditLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "audit_logs" do
    field :action, :string
    field :entity_type, :string
    field :entity_id, :integer
    field :metadata, :map, default: %{}

    belongs_to :user, Backend.Accounts.User

    timestamps(updated_at: false)
  end

  def changeset(audit_log, attrs) do
    audit_log
    |> cast(attrs, [:action, :entity_type, :entity_id, :metadata, :user_id])
    |> validate_required([:action, :entity_type, :entity_id])
  end
end
