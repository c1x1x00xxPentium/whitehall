class FeaturedImageData < ApplicationRecord
  mount_uploader :file, FeaturedImageUploader, mount_on: :carrierwave_image

  belongs_to :featured_imageable, polymorphic: true

  has_many :assets,
           as: :assetable,
           inverse_of: :assetable

  validates :file, presence: true
  validates :featured_imageable, presence: true

  validates_with ImageValidator, size: [960, 640]

  delegate :url, to: :file

  def filename
    file&.file&.filename
  end

  def all_asset_variants_uploaded?
    asset_variants = assets.map(&:variant).map(&:to_sym)
    required_variants = FeaturedImageUploader.versions.keys.push(:original)

    return false if (required_variants - asset_variants).any?

    assets_match_updated_image_filename
  end

  def republish_on_assets_ready
    if all_asset_variants_uploaded?
      logger.info("FeaturedImageData #{id} (#{featured_imageable_type}:#{featured_imageable_id}) republishing after all asset variants are uploaded")
      featured_imageable.republish_to_publishing_api_async if featured_imageable.respond_to? :republish_to_publishing_api_async
      featured_imageable.republish_dependent_documents if featured_imageable.respond_to? :republish_dependent_documents
    end
  end

private

  def assets_match_updated_image_filename
    assets.reject { |asset| asset.filename.include?(carrierwave_image) }.empty?
  end
end
