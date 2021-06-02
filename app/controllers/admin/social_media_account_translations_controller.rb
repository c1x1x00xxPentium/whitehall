class Admin::SocialMediaAccountTranslationsController < Admin::BaseController
  include TranslationControllerConcern

private

  def create_redirect_path
    edit_admin_organisation_social_media_account_translation_path(@socialable, @social_media_account, id: translation_locale)
  end

  def update_redirect_path
    admin_organisation_social_media_accounts_path(@socialable)
  end

  def destroy_redirect_path
    admin_organisation_social_media_accounts_path(@socialable)
  end

  def load_translatable_item
    @socialable = Organisation.friendly.find(params[:organisation_id])
    @social_media_account = @socialable.social_media_accounts.find(params[:social_media_account_id])
  end

  def load_translated_models
    @translated_social_media_account = LocalisedModel.new(@social_media_account, translation_locale.code, [:url])
    @english_social_media_account = LocalisedModel.new(@social_media_account, :en, [:url])
  end

  def translated_item_name
    @social_media_account.title
  end

  def translatable_item
    @translated_social_media_account
  end

  def translation_params
    params.require(:social_media_account).permit(
      :title,
      :url,
    )
  end
end
