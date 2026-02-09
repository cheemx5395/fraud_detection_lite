class Api::TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transaction, only: [ :show ]

  def index
    limit = params[:limit]&.to_i || 20
    offset = params[:offset]&.to_i || 0

    transactions = current_user.transactions
                               .order(created_at: :desc)
                               .limit(limit)
                               .offset(offset)

    render json: {
      data: transactions.map { |t| transaction_response(t) }
    }, status: :ok
  end

  def show
    render json: {
      data: transaction_detail_response(@transaction)
    }, status: :ok
  end

  def summary
    transactions = current_user.transactions

    summary_data = {
      total_transactions: transactions.count,
      allowed_transactions: transactions.allowed.count,
      flagged_transactions: transactions.flagged.count,
      blocked_transactions: transactions.blocked.count,
      triggered_factors_breakdown: Transaction.from(
                                                current_user.transactions.unscope(:order)
                                                            .select("unnest(triggered_factors) AS factor"),
                                                :t
                                              ).group(:factor).count
    }

    # Recent activity - use a more robust way to handle dates
    begin
      recent_activity = transactions.where("created_at > ?", 7.days.ago)
                                    .group("created_at::date")
                                    .count
                                    .transform_keys(&:to_s)
      summary_data[:recent_daily_activity] = recent_activity
    rescue => e
      Rails.logger.error "Summary API Date Error: #{e.message}"
      # Fallback to Ruby-side grouping if SQL fails
      recent_data = transactions.where("created_at > ?", 7.days.ago).pluck(:created_at)
      summary_data[:recent_daily_activity] = recent_data.map(&:to_date).tally.transform_keys(&:to_s)
    end

    render json: { data: summary_data }, status: :ok
  end

  def create
    # Strict type validation for amount - only accept Numeric (Integer, Float, Decimal)
    # Reject strings even if they contain numbers to prevent abrupt failure/unexpected behavior
    amount_param = params[:amount]
    unless amount_param.is_a?(Numeric)
      render json: {
        error: {
          message: "Amount must be a numeric value (provided #{amount_param.class})"
        }
      }, status: :bad_request
      return
    end

    # Get or initialize user behavior profile
    profile = current_user.user_behavior_profile || current_user.create_user_behavior_profile
    # Calculate fraud scores
    fraud_analysis = FraudDetectionService.analyze(
      user: current_user,
      profile: profile,
      amount: transaction_params[:amount].to_f,
      mode: transaction_params[:mode]
    )

    # Create transaction
    transaction = current_user.transactions.build(
      amount: transaction_params[:amount],
      mode: transaction_params[:mode],
      risk_score: fraud_analysis[:risk_score],
      triggered_factors: fraud_analysis[:triggered_factors],
      decision: fraud_analysis[:decision],
      amount_deviation_score: fraud_analysis[:amount_deviation_score],
      frequency_deviation_score: fraud_analysis[:frequency_deviation_score],
      mode_deviation_score: fraud_analysis[:mode_deviation_score],
      time_deviation_score: fraud_analysis[:time_deviation_score]
    )

    if transaction.save
      # Update user behavior profile
      ProfileUpdateService.update_profile(profile, transaction)

      render json: {
        data: {
          id: transaction.id,
          decision: transaction.decision,
          risk_score: transaction.risk_score,
          triggered_factors: transaction.triggered_factors
        }
      }, status: :created
    else
      render json: {
        error: {
          message: transaction.errors.full_messages.join(", ")
        }
      }, status: :unprocessable_entity
    end
  end

  def bulk
    unless params[:file].present?
      render json: { error: { message: "No file provided" } }, status: :bad_request
      return
    end

    summary = BulkIngestionService.process(
      current_user,
      params[:file].path,
      params[:file].original_filename
    )

    if summary[:errors].any? && summary[:processed_rows].zero?
      render json: {
        error: {
          message: "Ingestion failed heavily",
          details: summary[:errors].first(5)
        }
      }, status: :unprocessable_entity
    else
      render json: {
        message: "Ingestion complete",
        data: summary
      }, status: :ok
    end
  end

  private

  def set_transaction
    @transaction = current_user.transactions.find_by(id: params[:id])
    unless @transaction
      render json: {
        error: { message: "Transaction not found" }
      }, status: :not_found
    end
  end

  def transaction_params
    params.permit(:amount, :mode)
  end

  def transaction_response(transaction)
    {
      id: transaction.id,
      user_id: transaction.user_id,
      amount: transaction.amount.to_f,
      mode: transaction.mode,
      risk_score: transaction.risk_score,
      triggered_factors: transaction.triggered_factors,
      decision: transaction.decision,
      created_at: transaction.created_at.iso8601
    }
  end

  def transaction_detail_response(transaction)
    {
      id: transaction.id,
      user_id: transaction.user_id,
      amount: transaction.amount.to_f,
      mode: transaction.mode,
      risk_score: transaction.risk_score,
      triggered_factors: transaction.triggered_factors,
      decision: transaction.decision,
      amount_deviation_score: transaction.amount_deviation_score,
      frequency_deviation_score: transaction.frequency_deviation_score,
      mode_deviation_score: transaction.mode_deviation_score,
      time_deviation_score: transaction.time_deviation_score,
      created_at: transaction.created_at.iso8601,
      updated_at: transaction.updated_at.iso8601
    }
  end
end
