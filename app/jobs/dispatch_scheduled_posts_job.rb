class DispatchScheduledPostsJob < ApplicationJob
  queue_as :default

  def perform
    return unless Integration.social_unlocked?
    SocialPost.due.find_each do |post|
      post.update_columns(status: "publishing")
      PublishSocialPostJob.perform_later(post.id, post.created_by_id)
    end
  end
end
