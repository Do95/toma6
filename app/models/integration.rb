class Integration < ApplicationRecord
  include Auditable
  extend FriendlyId
  friendly_id :provider, use: :finders # «meta» en lugar del id

  encrypts :app_secret
  encrypts :user_access_token
  encrypts :page_access_token

  belongs_to :connected_by, class_name: "User", optional: true

  validates :provider, presence: true, uniqueness: true
  validates :graph_version, format: { with: /\Av\d+\.\d+\z/, message: "debe tener el formato v23.0" }

  def self.permission_resource = :integrations

  def self.meta = find_by(provider: "meta")
  def self.meta! = find_or_create_by!(provider: "meta")

  # Una función de redes se "desbloquea" cuando hay una página conectada y la red está activa.
  def self.social_unlocked? = meta&.any_ready? || false

  def display_name = "Integración con Meta (Facebook / Instagram)"

  def app_configured? = app_id.present? && app_secret.present?
  def page_connected? = page_id.present? && page_access_token.present?
  def instagram_linked? = instagram_account_id.present?

  def facebook_ready? = page_connected? && facebook_enabled?
  def instagram_ready? = page_connected? && instagram_linked? && instagram_enabled?
  def any_ready? = facebook_ready? || instagram_ready?

  def disconnect!
    update!(user_access_token: nil, user_token_expires_at: nil, page_id: nil, page_name: nil,
            page_access_token: nil, instagram_account_id: nil, instagram_username: nil,
            facebook_enabled: false, instagram_enabled: false, connected_at: nil,
            connected_by: nil, last_error: nil)
  end
end
