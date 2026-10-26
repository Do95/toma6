# Textos nuevos de la invitación (más generales y amigables). Solo se actualiza la
# plantilla guardada si sigue con el texto original: si alguien la editó, no se toca.
class RefreshInvitationCopy < ActiveRecord::Migration[8.0]
  OLD = {
    subject: "{{invitado_por}} te invitó al panel de {{sitio}}",
    heading: "Te sumamos al equipo",
    body: "Hola {{primer_nombre}},\n\n**{{invitado_por}}** te invitó al sitio de **{{sitio}}** como **{{rol}}**.\n\nPara entrar, creá tu contraseña con el botón de abajo. Vas a ingresar siempre con este correo: {{correo}}.\n\nEl enlace sirve hasta el {{vence}}. Si vence, pedile a quien te invitó que te lo reenvíe.",
    button_label: "Crear mi contraseña"
  }.freeze

  NEW = {
    name: "Invitación",
    subject: "{{primer_nombre}}, te esperamos en {{sitio}}",
    heading: "¡Te damos la bienvenida!",
    body: "Hola {{primer_nombre}}:\n\n{{invitado_por}} te invitó a sumarte a **{{sitio}}**. Ya tenés una cuenta esperándote con el rol de **{{rol}}**.\n\nSolo falta un paso: creá tu contraseña y ya podés entrar. Para ingresar vas a usar este correo: {{correo}}.\n\n==La invitación vale hasta el {{vence}}.== Si se vence, no pasa nada: pedí que te la vuelvan a enviar.\n\n¡Nos vemos adentro!",
    button_label: "Activar mi cuenta"
  }.freeze

  class Template < ActiveRecord::Base
    self.table_name = "email_templates"
  end

  def up
    template = Template.find_by(key: "user_invitation")
    return unless template
    template.update_columns(name: NEW[:name])
    return unless OLD.all? { |field, text| template[field].to_s == text }
    template.update_columns(NEW.except(:name).merge(updated_at: Time.current))
  end

  def down
    template = Template.find_by(key: "user_invitation")
    return unless template && NEW.except(:name).all? { |field, text| template[field].to_s == text }
    template.update_columns(OLD.merge(name: "Invitación al panel"))
  end
end
