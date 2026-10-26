# Invitaciones al panel: la persona recibe un correo y crea su propia contraseña
class AddInvitationsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :invited_at, :datetime
    add_column :users, :invitation_accepted_at, :datetime
    add_reference :users, :invited_by, foreign_key: { to_table: :users, on_delete: :nullify }
  end
end
