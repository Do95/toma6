# Código corto por usuario (ej. DM01): identifica quién creó cada cotización y va en la URL del panel
class AddCodeToUsers < ActiveRecord::Migration[8.0]
  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  def up
    add_column :users, :code, :string
    taken = []
    MigrationUser.order(:id).each do |user|
      words = I18n.transliterate(user.name.to_s).upcase.scan(/[A-Z]+/)
      prefix = words.size > 1 ? "#{words.first[0]}#{words.last[0]}" : (words.first.to_s[0, 2].presence || "US")
      prefix = prefix.ljust(2, "X")
      n = 1
      n += 1 while taken.include?(format("%s%02d", prefix, n))
      code = format("%s%02d", prefix, n)
      taken << code
      user.update_columns(code: code)
    end
    change_column_null :users, :code, false
    add_index :users, :code, unique: true
  end

  def down
    remove_index :users, :code
    remove_column :users, :code
  end
end
