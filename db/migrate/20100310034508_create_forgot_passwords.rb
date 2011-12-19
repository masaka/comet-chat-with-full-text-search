class CreateForgotPasswords < ActiveRecord::Migration
  def self.up
    create_table "forgot_passwords" do |t|
      t.integer :user_id
      t.string :reset_code
      t.datetime :expiration_date

      t.timestamps
    end
  end

  def self.down
    drop_table "forgot_passwords"
  end
end
