class ChangeEncodingForSocialMediaAccountTranslationsUrls < ActiveRecord::Migration[6.0]
  def up
    execute "ALTER TABLE social_media_account_translations CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
  end

  def down
    execute "ALTER TABLE social_media_account_translations CONVERT TO CHARACTER SET utf8 COLLATE utf8;"
  end
end
