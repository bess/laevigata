require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'Test for improperly exposed data', smoke: true, type: :feature do

  describe "an etd show page for an embargoed work" do
    it 'loads the home page' do
      etds = %w[
      r781wg01v
      0z708w40c
      jh343s28d
      6h440s459
      gx41mh844
      ]
      visit "https://admin:don'tcrawlme@staging-etd.library.emory.edu/concern/etds/#{etds[0]}?locale=en"
      expect(page).to have_content("File download under embargo")
    end
  end
end
