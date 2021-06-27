class CreateSocialMediaAccountTranslations < ActiveRecord::Migration[6.0]
  def change
    create_table :social_media_account_translations, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
      t.string :url
      t.string :title
      t.string :locale, null: false
      t.integer :social_media_account_id, null: false

      t.timestamps

      t.index :locale, name: :index_on_locale
      t.index :social_media_account_id, name: :index_on_social_media_account
    end
  end
end
