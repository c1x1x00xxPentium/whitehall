class RemoveLocaleFromSocialMediaAccounts < ActiveRecord::Migration[6.0]
  def change
    remove_column :social_media_accounts, :locale, :string
  end
end
