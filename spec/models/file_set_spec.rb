require 'rails_helper'

RSpec.describe FileSet do
  subject(:file_set) { described_class.new }

  describe '#admin_set' do
    it 'has no admin_set of its own' do
      expect(file_set.admin_set).to be_nil
    end

    context 'when it belongs to a work' do
      let(:etd)       { FactoryBot.build(:etd, admin_set: admin_set) }
      let(:admin_set) { FactoryBot.create(:admin_set) }

      before do
        etd.ordered_members << file_set
        etd.save
      end

      it 'gives the admin_set for the parent work' do
        expect(file_set.admin_set).to eq admin_set
      end
    end
  end

  describe '#visibility' do
    subject(:file_set) { FactoryBot.build(:file_set, visibility: open) }

    let(:open)       { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
    let(:restricted) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }

    it 'can set to restricted' do
      expect { file_set.visibility = restricted }
        .to change { file_set.visibility }
        .to restricted
    end

    it 'sets visibility to restricted for file restricted' do
      expect { file_set.visibility = VisibilityTranslator::FILES_EMBARGOED }
        .to change { file_set.visibility }
        .to restricted
    end

    it 'sets visibility to restricted for toc restricted' do
      expect { file_set.visibility = VisibilityTranslator::TOC_EMBARGOED }
        .to change { file_set.visibility }
        .to restricted
    end

    it 'sets visibility to restricted for all restricted' do
      expect { file_set.visibility = VisibilityTranslator::ALL_EMBARGOED }
        .to change { file_set.visibility }
        .to restricted
    end
  end

  describe '#hidden' do
    it 'is false without a parent' do
      expect(file_set).not_to be_hidden
    end

    context 'when it belongs to a work' do
      let(:etd) { FactoryBot.build(:etd, hidden: true) }

      before do
        etd.ordered_members << file_set
        etd.save
      end

      it 'gives the hidden status for the parent work' do
        expect(file_set).to be_hidden
      end
    end
  end

  context 'with a new FileSet' do
    its(:pcdm_use) { is_expected.to be_nil }
    its(:embargo_length) { is_expected.to be_nil }
    its(:premis?) { is_expected.to be false }
    its(:primary?) { is_expected.to be false }
    its(:supplementary?) { is_expected.to be true }
    its(:title) { is_expected.to eq [] }
    its(:description) { is_expected.to eq [] }
    its(:file_type) { is_expected.to be_nil }
  end

  context 'when original' do
    subject(:file_set) { described_class.new(pcdm_use: described_class::ORIGINAL) }

    its(:pcdm_use) { is_expected.to eq described_class::ORIGINAL }

    it { is_expected.not_to be_premis }
    it { is_expected.not_to be_primary }
    it { is_expected.not_to be_supplementary }
    it { is_expected.to be_original }
  end

  context 'when premis' do
    subject(:file_set) { described_class.new(pcdm_use: described_class::PREMIS) }

    its(:pcdm_use) { is_expected.to eq described_class::PREMIS }

    it { is_expected.to be_premis }
    it { is_expected.not_to be_primary }
    it { is_expected.not_to be_supplementary }
    it { is_expected.not_to be_original }
  end

  context 'when primary' do
    subject(:file_set) { described_class.new(pcdm_use: described_class::PRIMARY) }

    its(:pcdm_use) { is_expected.to eq described_class::PRIMARY }

    it { is_expected.not_to be_premis }
    it { is_expected.to be_primary }
    it { is_expected.not_to be_supplementary }
    it { is_expected.not_to be_original }
  end

  context 'when supplementary' do
    subject(:file_set) { described_class.new(pcdm_use: described_class::SUPPLEMENTARY) }

    its(:pcdm_use) { is_expected.to eq described_class::SUPPLEMENTARY }

    it { is_expected.not_to be_premis }
    it { is_expected.not_to be_primary }
    it { is_expected.to be_supplementary }
    it { is_expected.not_to be_original }
  end
end
