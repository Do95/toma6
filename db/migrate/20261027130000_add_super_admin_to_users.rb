# Super admin: el usuario creado por el seeder. Es el único que puede eliminar
# definitivamente; los demás solo envían a la papelera y restauran.
class AddSuperAdminToUsers < ActiveRecord::Migration[8.0]
  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  def up
    add_column :users, :super_admin, :boolean, null: false, default: false
    # El del seeder (ADMIN_EMAIL); si no existe, el administrador más antiguo
    seed = MigrationUser.find_by(email: ENV.fetch("ADMIN_EMAIL", "admin@toma6.com"), deleted_at: nil) ||
           MigrationUser.where(role: "admin", deleted_at: nil).order(:id).first
    seed&.update_columns(super_admin: true, role: "admin", active: true)
  end

  def down
    remove_column :users, :super_admin
  end
end
