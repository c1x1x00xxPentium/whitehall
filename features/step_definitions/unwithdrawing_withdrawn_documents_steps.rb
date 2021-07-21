When(/^I unwithdraw the publication$/) do
  publication = Publication.last
  visit admin_edition_path(publication)

  click_link "Unwithdraw"
  click_button "Unwithdraw"

  @latest_published_edition = publication.document.published_edition

  expect(:superseded).to eq(publication.reload.current_state)
  expect(:published).to eq(@latest_published_edition.current_state)
end

Then(/^I should be redirected to the latest edition of the publication$/) do
  expect(page).to have_current_path(admin_edition_path(@latest_published_edition))
end
