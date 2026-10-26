# Matriz de permisos por rol.
#   read    ver
#   write   crear y editar
#   delete  enviar a la papelera
#   restore restaurar desde la papelera
#   purge   eliminar definitivamente (solo el super admin, sea cual sea el rol)
module Permissions
  ALL = %i[read write delete restore purge].freeze
  RW = %i[read write delete restore].freeze

  MATRIX = {
    "admin" => :all,
    "editor" => {
      dashboard: [:read], content: RW, social: RW, sales: [:read], activity: [:read], trash: %i[read restore]
    },
    "sales" => {
      dashboard: [:read], content: [:read], sales: RW, activity: [:read], trash: %i[read restore]
    },
    "viewer" => {
      dashboard: [:read], content: [:read], sales: [:read], social: [:read], activity: [:read]
    }
  }.freeze

  RESOURCES = %i[dashboard content sales social integrations users settings activity trash jobs].freeze

  def self.allowed?(user, resource, action = :read)
    return false unless user
    return user.super_admin? if action.to_sym == :purge
    rules = MATRIX[user.role]
    return true if rules == :all
    Array(rules&.dig(resource.to_sym)).include?(action.to_sym)
  end
end
