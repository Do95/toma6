class PublishSocialPostJob < ApplicationJob
  queue_as :default

  def perform(post_id, user_id = nil)
    Current.user = User.find_by(id: user_id)
    post = SocialPost.kept.find_by(id: post_id)
    return unless post && %w[scheduled publishing failed draft].include?(post.status)
    SocialPublisher.call(post)
  end
end
