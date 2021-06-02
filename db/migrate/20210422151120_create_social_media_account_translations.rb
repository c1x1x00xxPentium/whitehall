class CreateSocialMediaAccountTranslations < ActiveRecord::Migration[6.0]
  def up
    SocialMediaAccount.create_translation_table!({ title: :string }, { migrate_data: true })
  end

  def down
    SocialMediaAccount.drop_translation_table! migrate_data: true
  end
end
