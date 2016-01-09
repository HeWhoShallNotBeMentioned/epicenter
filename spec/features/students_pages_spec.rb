feature 'Student signs up via invitation' do

  let(:student) { FactoryGirl.create(:user_with_all_documents_signed) }

  scenario 'with valid information', js: true do
    student.invite!
    visit accept_student_invitation_path(student, invitation_token: student.raw_invitation_token)
    fill_in 'Name', with: 'Ryan Larson'
    select student.plan.name, from: 'student_plan_id'
    fill_in 'Password', with: 'password'
    fill_in 'Password confirmation', with: 'password'
    click_on 'Submit'
    expect(page).to have_content 'Your password was set successfully. You are now signed in.'
  end

  scenario 'with missing information', js: true do
    student.invite!
    visit accept_student_invitation_path(student, invitation_token: student.raw_invitation_token)
    fill_in 'Name', with: ''
    select student.plan.name, from: 'student_plan_id'
    click_on 'Submit'
    expect(page).to have_content 'error'
  end
end

feature 'Student cannot invite other students' do

  let (:student) { FactoryGirl.create(:student) }

  scenario 'student visits new_student_invitation path', js: true do
    login_as(student)
    visit new_student_invitation_path
    expect(page).to have_content 'You need to sign in or sign up before continuing'
  end
end


feature "Student signs in while class is not in session" do

  let(:future_course) { FactoryGirl.create(:future_course) }
  let(:student) { FactoryGirl.create(:student, course: future_course) }

  context "before adding a payment method" do
    it "takes them to the page to choose payment method" do
      student = FactoryGirl.create(:user_with_all_documents_signed)
      sign_in(student)
      visit new_payment_method_path
      expect(page).to have_content "How would you like to make payments"
    end
  end

  context "after entering bank account info but before verifying" do
    it "takes them to the payment methods page", :vcr do
      bank_account = FactoryGirl.create(:bank_account, student: student)
      sign_in student
      visit payment_methods_path
      expect(page).to have_content "Your payment methods"
      expect(page).to have_link "Verify Account"
    end
  end

  context "after verifying their bank account", :vcr do
    it "shows them their payment history" do
      verified_bank_account = FactoryGirl.create(:verified_bank_account, student: student)
      sign_in(student)
      visit payments_path
      expect(page).to have_content "Your payments"
    end
  end

  context "after adding a credit card", :vcr do
    it "shows them their payment history" do
      credit_card = FactoryGirl.create(:credit_card, student: student)
      sign_in(student)
      visit payments_path
      expect(page).to have_content "Your payments"
    end
  end
end

feature "Student visits homepage after logged in" do
  let(:student) { FactoryGirl.create(:user_with_all_documents_signed) }

  it "takes them to the correct path" do
    sign_in(student)
    visit root_path
    expect(current_path).to_not eq root_path
  end
end

feature "Student signs in while class is in session" do
  let(:student) { FactoryGirl.create(:user_with_all_documents_signed) }

  context "not at school" do
    it "takes them to the code reviews page" do
      sign_in(student)
      expect(current_path).to eq course_code_reviews_path(student.course)
      expect(page).to have_content "Code Reviews"
    end

    it "does not create an attendance record" do
      expect { sign_in(student) }.to change { AttendanceRecord.count }.by 0
    end
  end

  context "at school" do
    before { allow_any_instance_of(Ability).to receive(:is_local).and_return(true) }

    context "when soloing" do
      it "takes them to the welcome page" do
        sign_in(student)
        expect(current_path).to eq welcome_path
      end

      it "creates an attendance record for them" do
        expect { sign_in(student) }.to change { AttendanceRecord.count }.by 1
      end
    end

    context "when pairing" do
      let(:pair) { FactoryGirl.create(:user_with_all_documents_signed) }

      it "takes them to the welcome page" do
        sign_in(student, pair)
        expect(current_path).to eq welcome_path
      end

      it "creates an attendance record for them" do
        expect { sign_in(student, pair) }.to change { AttendanceRecord.count }.by 2
      end

      it 'creates and updates attendance records if one student has already signed in for the day' do
        FactoryGirl.create(:attendance_record, student: student)
        expect { sign_in(student, pair) }.to change { AttendanceRecord.count }.by 1
      end

      it "gives an error for an incorrect email" do
        visit new_student_session_path
        fill_in 'student_email', with: 'wrong'
        fill_in 'student_password', with: student.password
        fill_in 'pair_email', with: pair.email
        fill_in 'pair_password', with: pair.password
        click_button 'Pair sign in'
        expect(page).to have_content 'Invalid email or password.'
      end

      it "gives an error for an incorrect password" do
        visit new_student_session_path
        fill_in 'student_email', with: student.email
        fill_in 'student_password', with: 'wrong'
        fill_in 'pair_email', with: pair.email
        fill_in 'pair_password', with: pair.password
        click_button 'Pair sign in'
        expect(page).to have_content 'Invalid email or password.'
      end
    end
  end
end

feature 'Guest not signed in' do
  subject { page }

  context 'visits new subscrition path' do
    before { visit new_bank_account_path }
    it { should have_content 'You need to sign in'}
  end

  context 'visits edit verification path' do
    before { visit edit_bank_account_path(1) }
    it { should have_content 'You need to sign in' }
  end

  context 'visits payments path' do
    let(:student) { FactoryGirl.create(:student) }
    before { visit payments_path }
    it { should have_content 'You need to sign in' }
  end
end

feature 'unenrolled student signs in' do
  let(:student) { FactoryGirl.create(:unenrolled_student) }

  before { login_as(student, scope: :student) }

  it "takes them to the correct path" do
    visit root_path
    expect(current_path).to_not eq root_path
  end

  it 'student can view the payments page' do
    visit payments_path
    expect(page).to have_content 'Your payment methods'
  end

  it 'student can view the profile page' do
    visit edit_student_registration_path(student)
    expect(page).to have_content 'Profile'
  end
end
