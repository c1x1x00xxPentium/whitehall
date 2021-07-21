When(/^I go to speed tag a newly imported (publication|speech|news article|consultation|statistical data set)(?: "(.*?)")?(?: for "(.*?)"(?: and "(.*?)")?)?$/) do |edition_type, title, organisation1_name, organisation2_name|
  organisations = []
  organisations << find_or_create_organisation(organisation1_name) if organisation1_name
  organisations << find_or_create_organisation(organisation2_name) if organisation2_name
  @edition = create("imported_#{edition_type.tr(' ', '_')}", organisations: organisations, title: title || "default title")
  visit admin_edition_path(@edition)
end

Then(/^I should have to select the publication sub-type$/) do
  expect(page).to have_selector("select[id*=edition_publication_type_id]")
end

Then(/^I should have to select the speech type$/) do
  expect(page).to have_selector("select[id*=edition_speech_type_id]")
end

Then(/^I should have to select the deliverer of the speech$/) do
  expect(page).to have_selector("select[id*=edition_role_appointment_id]")
end

When(/^I should be able to tag the (?:publication|news article) with "([^"]*)"$/) do |label|
  expect(page).to have_selector("label.checkbox", text: /#{label}/)
end

When(/^I should not be able to tag the (?:publication|news article) with "([^"]*)"$/) do |label|
  expect(page).to_not have_selector("label.checkbox", text: /#{label}/)
end

Then(/^I should be able to select the world location "([^"]*)"$/) do |name|
  select name, from: "edition_world_location_ids"
end

When(/^I can only tag the (?:publication|news article) with "([^"]*)" once$/) do |label|
  expect(page).to have_selector("label.checkbox", text: /#{label}/, count: 1)
end

Then(/^I should be able to select the first group for the document collection "([^"]*)"$/) do |name|
  group = @document_collection.groups.first
  select "#{name} (#{group.heading})", from: "Document collection"
end

Then(/^I should be able to set the first published date$/) do
  expect(page).to have_selector("select[id*=edition_first_published_at_1i]")
  select_datetime "14-Dec-2011 10:30", from: "First published *"
end

Then(/^I should be able to set the delivered date of the speech$/) do
  expect(page).to have_selector("select[id*=edition_delivered_on_1i]")
  select_date "02-May-2013", from: "Delivered on"
end

Then(/^I should be able to set the consultation dates$/) do
  expect(page).to have_selector("select[id*=edition_opening_at]")
  expect(page).to have_selector("select[id*=edition_closing_at]")
end
