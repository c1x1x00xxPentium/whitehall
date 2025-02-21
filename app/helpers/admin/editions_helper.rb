module Admin::EditionsHelper
  def edition_type(edition)
    type = if edition.is_a?(Speech) && edition.speech_type.written_article?
             edition.speech_type.singular_name
           else
             edition.type.underscore.humanize
           end

    [type, edition.display_type].compact.uniq.join(": ")
  end

  def nested_attribute_destroy_checkbox_options(form, html_args = {})
    checked_value = "0"
    unchecked_value = "1"
    checked = form.object[:_destroy].present? ? (form.object[:_destroy] == checked_value) : form.object.persisted?
    [html_args.merge(checked:), checked_value, unchecked_value]
  end

  def admin_documents_header_link
    admin_header_link "Documents", admin_editions_path, /^#{Whitehall.router_prefix}\/admin\/(editions|publications|news_articles|consultations|speeches|collections)/
  end

  def link_to_filter(link, options, filter, html_options = {})
    tag.li(link_to(link, url_for(filter.options.slice("state", "type", "author", "organisation", "title", "world_location").merge(options)), html_options), class: active_filter_if_options_match_class(filter, options))
  end

  def active_filter_if_options_match_class(filter, options)
    current = options.keys.all? do |key|
      options[key].to_param == filter.options[key].to_param
    end

    "active" if current
  end

  def active_filter_unless_values_match_class(filter, key, *disallowed_values)
    filter_value = filter.options[key]
    "active" if filter_value && disallowed_values.none? { |disallowed_value| filter_value == disallowed_value }
  end

  def admin_organisation_filter_options(selected_organisation)
    organisations = Organisation.with_translations(:en).order(:name).excluding_govuk_status_closed || []
    closed_organisations = Organisation.with_translations(:en).closed || []
    if current_user.organisation
      organisations = [current_user.organisation] + (organisations - [current_user.organisation])
    end

    [
      [
        "",
        [
          {
            text: "All organisations",
            value: "",
            selected: selected_organisation.blank?,
          },
        ],
      ],
      [
        "Live organisations",
        organisations.map do |organisation|
          {
            text: organisation.select_name,
            value: organisation.id,
            selected: selected_organisation.to_s == organisation.id.to_s,
          }
        end,
      ],
      [
        "Closed organisations",
        closed_organisations.map do |organisation|
          {
            text: organisation.select_name,
            value: organisation.id,
            selected: selected_organisation.to_s == organisation.id.to_s,
          }
        end,
      ],
    ]
  end

  def admin_author_filter_options(current_user)
    other_users = User.enabled.to_a - [current_user]
    [["All authors", ""], ["Me (#{current_user.name})", current_user.id]] + other_users.map { |u| [u.name, u.id] }
  end

  def admin_state_filter_options
    [
      ["All states", "active"],
      %w[Draft draft],
      %w[Submitted submitted],
      %w[Rejected rejected],
      %w[Scheduled scheduled],
      %w[Published published],
      ["Force published (not reviewed)", "force_published"],
      %w[Withdrawn withdrawn],
      %w[Unpublished unpublished],
    ]
  end

  def admin_edition_state_text(edition)
    edition.withdrawn? ? "Withdrawn" : edition.state.humanize
  end

  def admin_world_location_filter_options(current_user)
    options = [["All locations", ""]]
    if current_user.world_locations.any?
      options << ["My locations", "user"]
    end
    options + WorldLocation.ordered_by_name.map { |l| [l.name, l.id] }
  end

  def viewing_all_active_editions?
    params[:state] == "active"
  end

  def speech_type_label_data
    label_data = SpeechType.all.inject({}) do |hash, speech_type|
      hash.merge(speech_type.id => {
        ownerGroup: I18n.t("document.speech.#{speech_type.owner_key_group}"),
        publishedExternallyLabel: t_delivered_on(speech_type),
        locationRelevant: speech_type.location_relevant,
      })
    end

    # copy default values from Transcript SpeechType for '' select option
    default_type = SpeechType.find_by_name("Transcript")
    label_data.merge("" => {
      ownerGroup: I18n.t("document.speech.#{default_type.owner_key_group}"),
      publishedExternallyLabel: t_delivered_on(default_type),
      locationRelevant: default_type.location_relevant,
    })
  end

  # Because of the unusual way lead organisations and supporting organisations
  # are managed through the single has_many through :organisations association,
  # We have to go through the join model to identify selected organisations
  # when rendering editions' organisation select fields. See the
  # Edition::Organisations mixin module to see why this is required.
  def lead_organisation_id_at_index(edition, index)
    edition.edition_organisations
            .select(&:lead?)
            .sort_by(&:lead_ordering)[index].try(:organisation_id)
  end

  # As above for the lead_organisation_id_at_index helper, this helper is
  # required to identify the selected supporting organisation at a given index
  # in the list supporting organisations for the edition.
  def supporting_organisation_id_at_index(edition, index)
    edition.edition_organisations.reject(&:lead?)[index].try(:organisation_id)
  end

  def standard_edition_form(edition)
    form_for form_url_for_edition(edition), as: :edition, html: { class: edition_form_classes(edition), multipart: true }, data: { module: "EditionForm LocaleSwitcher", "rtl-locales": Locale.right_to_left.collect(&:to_param) } do |form|
      concat render("standard_fields", form:, edition:)
      yield(form)
      concat render("settings_fields", form:, edition:)
      concat standard_edition_publishing_controls(form, edition)
    end
  end

  def edition_form_classes(edition)
    form_classes = ["edition-form js-edition-form"]
    form_classes << "js-supports-non-english" if edition.locale_can_be_changed?
    form_classes
  end

  def form_url_for_edition(edition)
    if edition.is_a? CorporateInformationPage
      [:admin, edition.owning_organisation, edition]
    else
      [:admin, edition]
    end
  end

  def tab_url_for_edition(edition)
    if edition.is_a? CorporateInformationPage
      if edition.new_record?
        url_for([:new, :admin, edition.owning_organisation, edition.class.model_name.param_key.to_sym])
      else
        url_for([:edit, :admin, edition.owning_organisation, edition])
      end
    elsif edition.new_record?
      url_for([:new, :admin, edition.class.model_name.param_key.to_sym])
    else
      url_for([:edit, :admin, edition])
    end
  end

  def default_edition_tabs(edition)
    { "Document" => tab_url_for_edition(edition) }.tap do |tabs|
      if edition.allows_attachments? && edition.persisted?
        text = if edition.attachments.count.positive?
                 "Attachments <span class='badge'>#{edition.attachments.count}</span>".html_safe
               else
                 "Attachments"
               end
        tabs[text] = admin_edition_attachments_path(edition)
      end

      if edition.is_a?(DocumentCollection) && !edition.new_record?
        tabs["Collection documents"] = admin_document_collection_groups_path(edition)
      end

      if edition.is_a?(DocumentCollection) && current_user.can_edit_email_overrides?
        tabs["Email notifications"] = admin_document_collection_edit_email_subscription_path(edition)
      end
    end
  end

  def standard_edition_publishing_controls(form, edition)
    tag.div(class: "publishing-controls") do
      if edition.change_note_required?
        concat render("change_notes", form:, edition:)
      end

      concat render("save_or_continue_or_cancel", form:, edition:)
    end
  end

  def warn_about_lack_of_contacts_in_body?(edition)
    if edition.is_a?(NewsArticle) && edition.news_article_type == NewsArticleType::PressRelease
      govspeak_embedded_contacts(edition.body).empty?
    else
      false
    end
  end

  def attachment_metadata_tag(attachment)
    labels = {
      isbn: "ISBN",
      unique_reference: "Unique reference",
      command_paper_number: "Command paper number",
      hoc_paper_number: "House of Commons paper number",
      parliamentary_session: "Parliamentary session",
    }
    parts = []
    labels.each do |attribute, label|
      value = attachment.send(attribute)
      parts << "#{label}: #{value}" if value.present?
    end
    tag.p(parts.join(", ")) if parts.any?
  end

  def translation_preview_links(edition)
    links = []

    if edition.available_in_english?
      links << [edition.public_url(draft: true), "Language: English"]
    end

    links + edition.non_english_translated_locales.map do |locale|
      [edition.public_url(locale: locale.code, draft: true),
       "Language: #{locale.native_and_english_language_name}"]
    end
  end

  def withdrawal_or_unpublishing(edition)
    edition.unpublishing.unpublishing_reason_id == UnpublishingReason::Withdrawn.id ? "withdrawal" : "unpublishing"
  end

  def specialist_sector_options_for_select
    @specialist_sector_options_for_select ||= LinkableTopics.new.raw_topics.sort
  end

  def legacy_specialist_sector_options_for_select
    @legacy_specialist_sector_options_for_select ||= LinkableTopics.new.topics
  end

  def specialist_sector_names(sector_content_ids)
    raw_specialist_sectors.select { |pair| sector_content_ids.include? pair.last }.map(&:first)
  end

  def raw_specialist_sectors
    @raw_specialist_sectors ||= LinkableTopics.new.raw_topics
  end

  def specialist_sector_name(sector_content_id)
    raw_specialist_sectors.select { |pair| pair.last == sector_content_id }.first.try(:first)
  end

  def show_similar_slugs_warning?(edition)
    !edition.document.live? && edition.document.similar_slug_exists?
  end

  def edition_is_a_novel?(edition)
    edition.body.split.size > 99_999
  end

  def edition_has_links?(edition)
    LinkCheckerApiService.has_links?(edition, convert_admin_links: false)
  end

  def show_link_check_report?(edition)
    # There is an edition that is over 200000 words long.
    # This causes timeouts when LinkCheckerApiService tries to extract links from the body.
    # This is an exceptional case, but it stops publishers editing their editions.
    # Short circuit the call to LinkCheckerApiService by testing for an edition being
    # over 99999 words long. The number was chosen because Wikipedia suggests 100000 words is
    # the lower length of a novel (https://en.wikipedia.org/wiki/Word_count#In_fiction).
    # Returning true from the first half of the "or" means the second half doesn't get computed.
    edition_is_a_novel?(edition) || edition_has_links?(edition)
  end

  def status_text(edition)
    if edition.unpublishing.present?
      "#{edition.state.capitalize} (unpublished #{time_ago_in_words(edition.unpublishing.created_at)} ago)"
    else
      edition.state.capitalize
    end
  end

  def reset_search_fields_query_string_params(user, filter_action, anchor)
    query_string_params = if user.organisation.present? && filter_action == admin_editions_path
                            "?state=active&organisation=#{user.organisation.id}"
                          else
                            "?state=active"
                          end

    filter_action + query_string_params + anchor
  end
end
