class ReportEmailService
  include Rails.application.routes.url_helpers

  def initialize(tokenService = nil, current_time = nil)
    @tokenService = tokenService || TokenService.new
    @current_time = current_time || DateTime.now
  end

  def entity
    "report-email-" + @current_time.to_s
  end

  def sendReport
    end_of_day = @current_time.end_of_day
    token      = @tokenService.generate_token(early_bird_dashboard_path, entity, end_of_day)
    cc         = EarlyBirdMember.active.pluck(:email).join(';')
    template   = {
      :name   => 'report-email',
      :entity => entity,
      :email  => 'pqtest@digital.justice.gov.uk',
      :token  => token,
      :cc     => cc
    }

    $statsd.increment "#{StatsHelper::TOKENS_GENERATE}.earlybird"
    LogStuff.tag(:mailer_report_email) do
      LogStuff.info { "Report  email to #{template[:email]} (name #{template[:name]}) [CCd to #{template[:cc]}]" }
      MailService::Pq.report_email(template)
    end
    token
  end
end
