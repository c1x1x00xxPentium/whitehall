Given(/^a detailed guide with section headings$/) do
  create(
    :published_detailed_guide,
    title: "Detailed guide with pages",
    summary: "Here's the summary of the guide",
    body: <<~BODY,
      ## Page 1

      Here's the content for page one

      ## Page 2

      Here's some content for page two

      ### Page 2, Section 1

      A subsection! Well I never.

      ### Page 2, Section 2

      And another! How rare.

      ## Page 3

      You were expecting something a bit more tabloid? Shame on you.
    BODY
  )
end

When(/^I view the detailed guide$/) do
  guide = DetailedGuide.find_by!(title: "Detailed guide with pages")
  visit detailed_guide_path(guide.document)
end

Then(/^I should see all pages of the detailed guide$/) do
  %w[page-1 page-2 page-3].each do |page_id|
    expect(page).to have_selector("h2##{page_id}", visible: true)
  end
end
