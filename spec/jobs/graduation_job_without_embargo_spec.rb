require 'rails_helper'
# For a work without an embargo, the GraduationJob should:
# * set the degree_awarded date
# * publish the work (workflow transition)
# * update the relevant User object to have the post-graduation email address
# * ensure there is no embargo on the work or its files
# * send notifications
describe GraduationJob, :clean, integration: true do
  context "a student with no requested embargo", :perform_jobs do
    let(:w) { WorkflowSetup.new("#{fixture_path}/config/emory/superusers.yml", "#{fixture_path}/config/emory/candler_admin_sets.yml", "/dev/null") }
    let(:user)       { FactoryBot.create(:user) }
    let(:ability)    { ::Ability.new(user) }
    let(:env)        { Hyrax::Actors::Environment.new(Etd.new, ability, attributes) }
    let(:attributes) do
      {
        title: ['Open Access Adventures'],
        depositor: user.user_key,
        post_graduation_email: ['me@after.graduation.com'],
        creator: ['Quest, Jan'],
        school: ["Candler School of Theology"],
        department: ["Divinity"],
        files_embargoed: false,
        abstract_embargoed: false,
        toc_embargoed: false,
        embargo_length: 'None - open access immediately',
        uploaded_files: [uploaded_file.id]
      }
    end
    let(:uploaded_file) do
      FactoryBot.create :primary_uploaded_file, user_id: user.id
    end
    let(:six_years_from_today) { Time.zone.today + 6.years }
    let(:open)       { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
    let(:restricted) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
    before do
      w.setup
      allow(Hyrax::Workflow::DegreeAwardedNotification).to receive(:send_notification)
      ActiveJob::Base.queue_adapter.filter = [AttachFilesToWorkJob]
      Hyrax::CurationConcern.actor.create(env)
    end
    it "performs the graduation process" do
      etd = Etd.last
      expect(etd.degree_awarded).to eq nil
      expect(etd.embargo).to eq nil
      expect(etd.embargo_length).to eq nil
      expect(etd.reload.file_sets.first.embargo).to eq nil
      expect(etd.file_sets.first).to have_attributes visibility: open
      expect(etd.visibility).to eq open
      graduation_job = described_class.new
      graduation_job.perform(etd.id, Time.zone.tomorrow)
      etd.reload
      expect(etd.visibility).to eq open

      # The ETD should now have a degree_awarded date
      expect(etd.degree_awarded).to eq Time.zone.tomorrow

      # An object must be "published" and "active" to be publicly visible
      expect(etd.to_sipity_entity.workflow_state_name).to eq "published"
      expect(etd.state).to eq Vocab::FedoraResourceStatus.active

      # The User object should now have the post_graduation_email, to be used
      # for sending post-graduation notifications (e.g., for embargo expiration)
      expect(user.reload.email).to eq(etd.post_graduation_email.first)

      # The work and attached files should still not have an embargo
      expect(etd.embargo).to eq nil
      expect(etd.file_sets.first.embargo).to eq nil

      # Attached files should be open
      expect(etd.file_sets.first).to have_attributes visibility: open

      # The `embargo_length` should be blank
      expect(etd.embargo_length).to eq nil

      # Notifications have been sent that the degree was awarded and the ETD was published
      expect(Hyrax::Workflow::DegreeAwardedNotification).to have_received(:send_notification)
    end
  end
end
