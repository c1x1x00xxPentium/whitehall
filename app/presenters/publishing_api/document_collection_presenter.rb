module PublishingApi
  class DocumentCollectionPresenter
    include UpdateTypeHelper

    attr_reader :update_type

    def initialize(item, update_type: nil)
      @item = item
      @update_type = update_type || default_update_type(item)
    end

    def content_id
      item.content_id
    end

    def content
      content = BaseItemPresenter.new(item).base_attributes
      content.merge!(
        description: item.summary,
        details: details,
        document_type: "document_collection",
        first_published_at: first_public_at.utc,
        public_updated_at: item.public_timestamp || item.updated_at,
        rendering_app: Whitehall::RenderingApp::WHITEHALL_FRONTEND,
        schema_name: "document_collection",
      )
      content.merge!(PayloadBuilder::PublicDocumentPath.for(item))
    end

    def links
      links = LinksPresenter.new(item).extract(
        %i(organisations policy_areas topics related_policies)
      )
      links.merge!(documents: item.documents.map(&:content_id))
      links.merge!(PayloadBuilder::TopicalEvents.for(item))
    end

  private

    attr_reader :item

    def details
      {
        first_public_at: first_public_at,
        change_history: item.change_history.as_json,
        collection_groups: collection_groups,
        body: govspeak_renderer.govspeak_edition_to_html(item),
        emphasised_organisations: item.lead_organisations.map(&:content_id),
      }.tap do |details_hash|
        details_hash.merge!(PayloadBuilder::PoliticalDetails.for(item))
        details_hash.merge!(PayloadBuilder::AccessLimitation.for(item))
      end
    end

    def first_public_at
      item.document.published? ? item.first_public_at : item.document.created_at
    end

    def collection_groups
      item.groups.map do |group|
        {
          title: group.heading,
          body: govspeak_renderer.govspeak_to_html(group.body),
          documents: group.documents.collect(&:content_id)
        }
      end
    end

    def govspeak_renderer
      @govspeak_renderer ||= Whitehall::GovspeakRenderer.new
    end
  end
end
