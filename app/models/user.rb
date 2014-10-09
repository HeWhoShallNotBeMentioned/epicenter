class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  validates :name, presence: true
  validates :plan_id, presence: true

  belongs_to :plan
  has_one :bank_account
  has_many :payments, through: :bank_account
  has_many :attendance_records

  def upfront_payment_due?
    plan.upfront_amount > 0 && payments.count == 0
  end

  def signed_in_today?
    attendance_records.today.exists?
  end

  def make_upfront_payment
    bank_account.payments.create!(amount: plan.upfront_amount)
  end

  def start_recurring_payments
    bank_account.update!(recurring_active: true)
    bank_account.payments.create!(amount: plan.recurring_amount)
  end
end
