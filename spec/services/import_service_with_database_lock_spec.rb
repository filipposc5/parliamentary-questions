require 'spec_helper'

describe 'ImportServiceWithDatabaseLock' do
  progress_seed

  before(:each) do
    @http_client = double('QuestionsHttpClient')
    allow(@http_client).to receive(:questions) { import_questions_for_today }

    questions_service = QuestionsService.new(@http_client)
    import_service_plain = ImportService.new(questions_service)

    @import_service = ImportServiceWithDatabaseLock.new(import_service_plain)


  end


  describe '#questions' do
    it 'should log the activity on the database when process a question' do

      @import_service.questions()

      logs = ImportLog.all
      logs[0].log_type.should eq('START')
      logs[1].log_type.should eq('SUCCESS')
      logs[2].log_type.should eq('SUCCESS')
      logs[3].log_type.should eq('FINISH')

    end

  end
end