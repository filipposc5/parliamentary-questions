class ReportSendEmailsController < ApplicationController
  before_action :authenticate_user!, PQUserFilter

  def send_emails
    service = ReportEmailService.new
    service.sendReport
    flash[:success] = 'Mail Report'
    redirect_to controller: 'early_bird_members', action: 'index'
  end
end
