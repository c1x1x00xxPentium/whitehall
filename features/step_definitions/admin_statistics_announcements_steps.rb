Given(/^a statistics announcement called "(.*?)" exists$/) do |announcement_title|
  @statistics_announcement = create(:statistics_announcement, title: announcement_title)
end

Given(/^a draft statistics publication called "(.*?)"$/) do |title|
  @statistics_publication = create(
    :publication,
    :draft,
    access_limited: false,
    publication_type_id: PublicationType::OfficialStatistics.id,
    title: title,
  )
end

Given(/^there is a statistics announcement by my organisation$/) do
  @organisation_announcement = create(:statistics_announcement, organisation_ids: [@user.organisation.id])
end

Given(/^there are statistics announcements by my organisation$/) do
  @past_announcement = create(
    :statistics_announcement,
    organisation_ids: [@user.organisation.id],
    current_release_date: create(:statistics_announcement_date, release_date: 1.day.ago),
    publication: create(:draft_statistics),
  )

  @future_announcement = create(
    :statistics_announcement,
    organisation_ids: [@user.organisation.id],
    current_release_date: create(:statistics_announcement_date, release_date: 1.week.from_now),
  )
end

Given(/^there are statistics announcements by my organisation that are unlinked to a publication$/) do
  @past_announcement = create(
    :statistics_announcement,
    organisation_ids: [@user.organisation.id],
    current_release_date: create(:statistics_announcement_date, release_date: 1.day.ago),
  )

  @tomorrow_announcement = create(
    :statistics_announcement,
    organisation_ids: [@user.organisation.id],
    current_release_date: create(:statistics_announcement_date, release_date: 1.day.from_now),
  )

  @next_week_announcement = create(
    :statistics_announcement,
    organisation_ids: [@user.organisation.id],
    current_release_date: create(:statistics_announcement_date, release_date: 1.week.from_now),
  )

  @next_year_announcement = create(
    :statistics_announcement,
    organisation_ids: [@user.organisation.id],
    current_release_date: create(:statistics_announcement_date, release_date: 1.year.from_now),
  )
end

When(/^I view the statistics announcements index page$/) do
  visit admin_statistics_announcements_path
end

Given(/^there is a statistics announcement by another organistion$/) do
  @other_organisation_announcement = create(:statistics_announcement)
end

Given(/^a cancelled statistics announcement exists$/) do
  @statistics_announcement = create(:cancelled_statistics_announcement)
end

Then(/^I should see my organisation's statistics announcements on the statistical announcements page by default$/) do
  visit admin_statistics_announcements_path

  expect(page).to have_selector("tr.statistics_announcement", text: @organisation_announcement.title)
  expect(page).to_not have_selector("tr.statistics_announcement", text: @other_organisation_announcement.title)
end

When(/^I filter statistics announcements by the other organisation$/) do
  select @other_organisation_announcement.organisations.first.name, from: "Organisation"
  click_on "Search"
end

Then(/^I should only see the statistics announcement of the other organisation$/) do
  expect(page).to have_selector("tr.statistics_announcement", text: @other_organisation_announcement.title)
  expect(page).to_not have_selector("tr.statistics_announcement", text: @organisation_announcement.title)
end

When(/^I link the announcement to the publication$/) do
  visit admin_statistics_announcement_path(@statistics_announcement)
  click_on "connect an existing draft"

  fill_in "title", with: "statistics"
  click_on "Search"
  find("li.ui-menu-item").click
end

Then(/^I should see that the announcement is linked to the publication$/) do
  expect(page).to have_current_path(admin_statistics_announcement_path(@statistics_announcement))
  expect(page).to have_content(
    "Announcement connected to draft document #{@statistics_publication.title}",
    normalize_ws: true,
  )
end

When(/^I announce an upcoming statistics publication called "(.*?)"$/) do |announcement_title|
  organisation = Organisation.first || create(:organisation)

  ensure_path admin_statistics_announcements_path
  click_on "Create announcement"
  choose "statistics_announcement_publication_type_id_5" # Statistics
  fill_in :statistics_announcement_title, with: announcement_title
  fill_in :statistics_announcement_summary, with: "Summary of publication"
  select_date 1.year.from_now.to_s, from: "Release date"
  select organisation.name, from: :statistics_announcement_organisation_ids

  click_on "Publish announcement"
end

When(/^I draft a document from the announcement$/) do
  visit admin_statistics_announcement_path(@statistics_announcement)
  click_on "Draft new document"
end

When(/^I save the draft statistics document$/) do
  fill_in "Body", with: "Statistics body text"
  check "Applies to all UK nations"
  click_on "Save"
end

When(/^I change the release date on the announcement$/) do
  visit admin_statistics_announcement_path(@statistics_announcement)
  click_on "Change release date"

  select_datetime "14-Dec-#{Time.zone.today.year.next} 09:30", from: "Release date"
  check "Confirmed date?"
  choose "Exact"
  click_on "Publish change of date"
end

When(/^I search for announcements containing "(.*?)"$/) do |keyword|
  visit admin_statistics_announcements_path
  fill_in "Title or slug", with: keyword
  select "All organisations", from: "Organisation"
  click_on "Search"
end

When(/^I cancel the statistics announcement$/) do
  visit admin_statistics_announcement_path(@statistics_announcement)
  click_on "Cancel statistics release"

  fill_in "Official reason for cancellation", with: "Cancelled because: reasons"
  click_on "Publish cancellation"
end

When(/^I change the cancellation reason$/) do
  visit admin_statistics_announcement_path(@statistics_announcement)

  click_on "Edit cancellation reason"
  fill_in "Official reason for cancellation", with: "Updated cancellation reason"
  click_on "Update cancellation reason"
end

Then(/^I should see the updated cancellation reason$/) do
  expect(page).to have_current_path(admin_statistics_announcement_path(@statistics_announcement))

  expect(page).to have_content("Statistics release cancelled")
  expect(page).to have_content("Updated cancellation reason")
end

Then(/^I should see that the statistics announcement has been cancelled$/) do
  ensure_path admin_statistics_announcement_path(@statistics_announcement)

  expect(page).to have_content("Statistics release cancelled")
  expect(page).to have_content("Cancelled because: reason")
end

Then(/^the document fields are pre-filled based on the announcement$/) do
  expect(page).to have_selector("input[id=edition_title][value='#{@statistics_announcement.title}']")
  expect(page).to have_selector("textarea[id=edition_summary]", text: @statistics_announcement.summary)
end

Then(/^the document becomes linked to the announcement$/) do
  publication = Publication.last
  visit admin_statistics_announcements_path(organisation_id: "")

  within record_css_selector(@statistics_announcement) do
    expect(page).to have_link(publication.title, href: admin_publication_path(publication))
  end
end

Then(/^I should see the announcement listed on the list of announcements$/) do
  announcement = StatisticsAnnouncement.last
  ensure_path admin_statistics_announcements_path

  expect(page).to have_content(announcement.title)
end

Then(/^I should (see|only see) a statistics announcement called "(.*?)"$/) do |single_or_multiple, title|
  expect(page).to have_selector("tr.statistics_announcement", count: 1) if single_or_multiple == "only see"
  expect(page).to have_selector("tr.statistics_announcement", text: title)
end

Then(/^the new date is reflected on the announcement$/) do
  expect(page).to have_content("14 December #{Time.zone.today.year.next} 9:30am")
end

Then(/^I should be able to filter both past and future announcements$/) do
  visit admin_statistics_announcements_path

  select "Future releases", from: "Release date"
  click_on "Search"

  expect(page).to have_selector("tr.statistics_announcement", text: @future_announcement.title)
  expect(page).to_not have_selector("tr.statistics_announcement", text: @past_announcement.title)

  select "Past announcements", from: "Release date"
  click_on "Search"

  expect(page).to have_selector("tr.statistics_announcement", text: @past_announcement.title)
  expect(page).to_not have_selector("tr.statistics_announcement", text: @future_announcement.title)
end

Then(/^I should be able to filter only the unlinked announcements$/) do
  visit admin_statistics_announcements_path

  select "All announcements", from: "Release date"
  check :unlinked_only
  click_on "Search"

  expect(page).to have_selector("tr.statistics_announcement", text: @future_announcement.title)
  expect(page).to_not have_selector("tr.statistics_announcement", text: @past_announcement.title)
end

Then(/^I should see a warning that there are upcoming releases without a linked publication$/) do
  expect(page).to have_content("2 imminent releases need a publication")
end

Then(/^I should be able to view these upcoming releases without a linked publication$/) do
  click_on "2 imminent releases"

  expect(page).to have_selector("tr.statistics_announcement", text: @tomorrow_announcement.title)
  expect(page).to have_selector("tr.statistics_announcement", text: @next_week_announcement.title)
  expect(page).to_not have_selector("tr.statistics_announcement", text: @past_announcement.title)
  expect(page).to_not have_selector("tr.statistics_announcement", text: @next_year_announcement.title)
end
