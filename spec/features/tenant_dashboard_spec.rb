require "spec_helper"

describe "Tenant Dashboard" do
  let!(:admin) { login_as_admin }

  let(:user_with_no_violations) { FactoryGirl.create(:user) }
  let(:user_with_recent_violations1) { FactoryGirl.create(:user) }
  let(:user_with_recent_violations2) { FactoryGirl.create(:user) }
  let(:user_with_old_violations) { FactoryGirl.create(:user) }
  let(:user_with_major_violation) { FactoryGirl.create(:user) }

  let(:time) { Time.parse('March 1, 2015 15:00:00') }

  before do
    FactoryGirl.create(:collaboration, user: admin, collaborator: user_with_no_violations)
    FactoryGirl.create(:collaboration, user: admin, collaborator: user_with_recent_violations1)
    FactoryGirl.create(:collaboration, user: admin, collaborator: user_with_recent_violations2)
    FactoryGirl.create(:collaboration, user: admin, collaborator: user_with_old_violations)
    FactoryGirl.create(:collaboration, user: admin, collaborator: user_with_major_violation)

    create_minor_violation(user_with_old_violations, time - 5.days)

    create_minor_violation(user_with_recent_violations1, time - 5.days)
    create_minor_violation(user_with_recent_violations1, time - 2.days)
    create_minor_violation(user_with_recent_violations1, time - 2.days)
    create_minor_violation(user_with_recent_violations1, time - 1.days)
    create_reading(user_with_recent_violations1, 77)

    create_minor_violation(user_with_recent_violations2, time - 2.days)
    create_reading(user_with_recent_violations2, 78)

    create_major_violation(user_with_major_violation, time - 1.days)
  end

  context "tenant list" do
    it "shows user information for all associated tenants" do
      visit user_path(admin)

      within "#collaborator-ul" do
        expect(page).to have_text user_with_no_violations.name
        expect(page).to have_text user_with_recent_violations1.name
        expect(page).to have_text user_with_recent_violations2.name
        expect(page).to have_text user_with_old_violations.name
      end
    end

    it "does not show users you are not associated with" do
      other_user = FactoryGirl.create(:user)
      create_minor_violation(other_user, time - 2.days)
      create_minor_violation(other_user, time - 1.days)

      visit user_path(admin)

      expect(page).to_not have_text other_user.name
    end
  end

  context "violations report" do
    it "shows users who have had violations in the last 3 days" do
      visit user_path(admin)

      within ".violations-report" do
        expect(page.all("tbody tr").length).to be 5
        expect(page).to have_text expected_text_for(user_with_recent_violations1, 3, 0)
        expect(page).to have_text expected_text_for(user_with_recent_violations2, 1, 0)
        expect(page).to have_text expected_text_for(user_with_no_violations, 0, 0)
        expect(page).to have_text expected_text_for(user_with_old_violations, 0, 0)
        expect(page).to have_text expected_text_for(user_with_major_violation, 0, 1)
      end
    end
  end

  def create_minor_violation(user, time)
    FactoryGirl.create(:reading, user: user, created_at: time, outdoor_temp: 30, temp: 65)
  end

  def create_major_violation(user, time)
    FactoryGirl.create(:reading, user: user, created_at: time, outdoor_temp: 30, temp: 63)
  end

  def create_reading(user, temp)
    FactoryGirl.create(:reading, user: user, created_at: 1.hour.ago, outdoor_temp: 32, temp: temp)
  end

  def expected_text_for(user, minor_violations_count, major_violations_count)
    return "#{user.name} #{user.address}, #{user.zip_code} #{user.current_temp} #{major_violations_count} #{minor_violations_count}"
  end
end
