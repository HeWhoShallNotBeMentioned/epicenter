class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  validates :name, presence: true
  validates :plan_id, presence: true
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  belongs_to :plan
  has_one :bank_account
  has_many :payments, through: :bank_account

  def upfront_payment_due?
    plan.upfront_amount > 0 && payments.count == 0
  end
end
