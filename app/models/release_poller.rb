# Heroku build release phase poller
class ReleasePoller
  attr_reader :args, :app_name, :build_id,
    :release_id, :command_id, :deployment_url,
    :user_id, :pipeline_name


  def self.run(args)
    poller = new(args)
    poller.run
    poller
  end

  def initialize(args = {})
    @args           = args
    @app_name       = args.fetch(:app_name)
    @build_id       = args.fetch(:build_id)
    @release_id     = args.fetch(:release_id)
    @command_id     = args.fetch(:command_id)
    @deployment_url = args.fetch(:deployment_url)
    @user_id        = args.fetch(:user_id)
    @pipeline_name  = args.fetch(:name)
  end

  def run
    if release
      release_completed
    elsif release_phase_is_still_running?
      ReleasePollerJob.set(wait: 10.seconds).perform_later(args)
    else
      build_and_release_expired
    end
  end

  def release
    @release ||= pipeline.reap_release(app_name, build_id, release_id)
  end

  private

  def release_phase_is_still_running?
    command.created_at > 30.minutes.ago
  end

  def release_completed
    payload = {
      state: "failure",
      target_url:  build_url(app_name, build_id),
      description: "Release phase completed."
    }
    payload[:state] = "success" if release.status == "succeeded"

    pipeline.create_deployment_status(deployment_url, payload)
  end

  def build_and_release_expired
    Rails.logger.info "Build expired for command: #{command.id}"
    payload = {
      state: "failure",
      target_url:  build_url(app_name, build_id),
      description: "Heroku build and release took longer than 30 minutes."
    }
    pipeline.create_deployment_status(deployment_url, payload)
  end

  def command
    @command ||= Command.find(command_id)
  end

  def user
    @user ||= User.find(user_id)
  end

  def pipeline
    @pipeline ||= user.pipeline_for(pipeline_name)
  end

  def build_url(app_name, build_id)
    "https://dashboard.heroku.com/apps/#{app_name}/activity/builds/#{build_id}"
  end
end
