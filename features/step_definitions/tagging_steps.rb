When(/^I continue to the tagging page$/) do
  click_button "Save and go to document summary"
  click_link "Add tags"
end

When(/^I navigate to the legacy tagging page$/) do
  click_button "Save"
  click_link "Add specialist topic tags"
end
