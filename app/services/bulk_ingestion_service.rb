class BulkIngestionService
  def self.process(user, file_path, original_filename)
    new(user, file_path, original_filename).process
  end

  def initialize(user, file_path, original_filename)
    @user = user
    @file_path = file_path
    @extension = File.extname(original_filename).downcase
    @profile = @user.user_behavior_profile || @user.create_user_behavior_profile
    @summary = {
      total_rows: 0,
      processed_rows: 0,
      failed_rows: 0,
      errors: []
    }
  end

  def process
    spreadsheet = open_spreadsheet
    header = spreadsheet.row(1).map(&:to_s).map(&:strip).map(&:downcase)

    # Expected headers: amount, mode, created_at
    amount_idx = header.index("amount")
    mode_idx = header.index("mode")
    created_at_idx = header.index("created_at")

    if amount_idx.nil? || mode_idx.nil? || created_at_idx.nil?
      @summary[:errors] << "Missing required headers: amount, mode, created_at. Found: #{header.join(', ')}"
      return @summary
    end

    Transaction.transaction do
      (2..spreadsheet.last_row).each do |i|
        @summary[:total_rows] += 1
        row = spreadsheet.row(i)

        # Skip empty rows
        next if row.all?(&:blank?)

        begin
          transaction_data = {
            amount: row[amount_idx],
            mode: row[mode_idx],
            created_at: parse_time(row[created_at_idx])
          }

          process_row(transaction_data)
          @summary[:processed_rows] += 1

          # Update profile every 10 rows to keep analysis fresh but reduce DB load
          if @summary[:processed_rows] % 10 == 0
            ProfileUpdateService.recalibrate(@profile)
            @profile.reload
          end

        rescue => e
          @summary[:failed_rows] += 1
          @summary[:errors] << "Row #{i}: #{e.message}"
        end
      end

      # Final recalibration if not already done on last batch
      ProfileUpdateService.recalibrate(@profile) if @summary[:processed_rows] % 10 != 0
    end

    @summary
  end

  private

  def open_spreadsheet
    case @extension
    when ".csv" then Roo::CSV.new(@file_path)
    when ".xls" then Roo::Excel.new(@file_path)
    when ".xlsx" then Roo::Excelx.new(@file_path)
    else
      raise "Unknown file type: #{@extension}"
    end
  end

  def parse_time(value)
    return value if value.is_a?(Time) || value.is_a?(DateTime)
    parsed = Time.zone.parse(value.to_s)
    raise "Invalid date format: #{value}" if parsed.nil?
    parsed
  end

  def process_row(data)
    # Analyze against current profile state
    analysis = FraudDetectionService.analyze(
      user: @user,
      profile: @profile,
      amount: data[:amount].to_f,
      mode: data[:mode].to_s.upcase
    )

    @user.transactions.create!(
      amount: data[:amount],
      mode: data[:mode].to_s.upcase,
      created_at: data[:created_at],
      risk_score: analysis[:risk_score],
      triggered_factors: analysis[:triggered_factors],
      decision: analysis[:decision],
      amount_deviation_score: analysis[:amount_deviation_score],
      frequency_deviation_score: analysis[:frequency_deviation_score],
      mode_deviation_score: analysis[:mode_deviation_score],
      time_deviation_score: analysis[:time_deviation_score]
    )
  end
end
