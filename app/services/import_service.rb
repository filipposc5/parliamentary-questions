class ImportService
  def initialize(questionsService = QuestionsService.new)
    @questionsService = questionsService
    @progress_unallocated = Progress.unassigned
  end

  def questions_with_callback(args = { dateFrom: Date.today} , &block)
    t_start = Time.now

    questions = @questionsService.questions(args)
    return unless questions.any?

    LogStuff.info { "Import: obtained #{questions.count} from API" }
    questions.each do |q|
      import_one_question(q, &block)
    end

    update_date_for_answer_relatives

    elapsed_seconds = Time.now - t_start
    $statsd.timing("#{StatsHelper::IMPORT}.import_time", elapsed_seconds * 1000)
  end

  def questions_by_uin_with_callback(uin, &block)
    q = @questionsService.questions_by_uin(uin)
    import_one_question(q, &block)
  end


  def questions(args = { dateFrom: Date.today} )
    questions_processed = Array.new
    errors = Array.new

    questions_with_callback(args) { |result|
      process_result(result, questions_processed, errors)
    }

    {questions: questions_processed, errors: errors}
  end

  def process_result(result, q_p, err)
    if result[:error].empty?
      q_p.push(result[:question])
    else
      err.push({ message: result[:error], question: result[:question] })
    end
  end

  def questions_by_uin(uin)
    questions_processed = Array.new
    errors = Array.new

    questions_by_uin_with_callback(uin) { |result|
      process_result(result, questions_processed, errors)
    }
    {questions: questions_processed, errors: errors}
  end

protected

  def import_one_question(q, &block)
    pq = Pq.find_or_initialize_by(uin: q['Uin'])

    status = 'new' if pq.new_record?

    pq.update(
        uin: q['Uin'],
        raising_member_id: q['TablingMember']['MemberId'],
        question: q['Text'],
        tabled_date: q['TabledDate'],
        member_name: q['TablingMember']['MemberName'],
        member_constituency: q['TablingMember']['Constituency'],
        house_name: q['House']['HouseName'],
        date_for_answer: get_date_for_answer(pq, q['DateForAnswer']),
        registered_interest: q['RegisteredInterest'],
        question_type: q['QuestionType'],
        preview_url: q['Url'],
        question_status: q['QuestionStatus'],
        transferred: get_transfer(pq),
        progress_id: get_progress_id(pq)
    )

    status ||= get_changed(pq)

    yield ({question: q, status: status, error: pq.errors.full_messages})
  end

  def get_changed(pq)
    if pq.previous_changes.empty?
      'unchanged'
    else
      'changed'
    end
  end

  def get_progress_id(pq)
    pq.progress_id || @progress_unallocated.id
  end

  def get_transfer(pq)
    pq.transferred || false
  end

  def get_date_for_answer(pq, incoming_date)
    date_for_answer = pq.date_for_answer

    if date_for_answer.nil?
      date_for_answer = incoming_date
    end

    date_for_answer
  end

  def update_date_for_answer_relatives
    number_of_pqs_date_for_answer_relative_updates = 0
    pqs = Pq.all
    pqs.each do |pq|
      if pq.date_for_answer.nil?
        pq.date_for_answer_has_passed = true
        pq.days_from_date_for_answer = LARGEST_POSTGRES_INTEGER
      else
        pq.date_for_answer_has_passed = pq.date_for_answer < Date.today
        pq.days_from_date_for_answer = (pq.date_for_answer - Date.today).abs
      end
      pq.save
      number_of_pqs_date_for_answer_relative_updates +=1
    end

    LogStuff.info "Import process, updated #{number_of_pqs_date_for_answer_relative_updates} questions with date_for_answer_relatives"
    number_of_pqs_date_for_answer_relative_updates
  end
end
