class SpreeShared::TenantInitializer
  attr_reader :db_name

  def initialize(db_name)
    @db_name = db_name
    ENV['AUTO_ACCEPT'] = 'true'
    ENV['SKIP_NAG'] = 'yes'
  end

  def create_database
    ActiveRecord::Base.establish_connection #make sure we're talkin' to db
    ActiveRecord::Base.connection.execute("DROP SCHEMA IF EXISTS #{ActiveRecord::Base.connection.quote_table_name(db_name)} CASCADE")
    Apartment::Tenant.create db_name
  end

  def load_seeds
    Apartment::Tenant.switch(db_name) do
      Rails.application.load_seed
    end
  end

  def load_spree_sample_data
    Apartment::Tenant.switch(db_name) do
      if ENV['LOAD_SAMPLE_DATA_IN_TENANT']
        SpreeSample::Engine.load_samples
      end
    end
  end

  def create_admin
    Apartment::Tenant.switch(db_name) do
      email = ENV[db_name.upcase+'_ADMIN_EMAIL'] || ENV['ADMIN_EMAIL'] || "spree@example.com"
      password = ENV[db_name.upcase+'_ADMIN_PASSWORD'] || ENV['ADMIN_PASSWORD'] || "spree123"

      unless Spree::User.find_by_email(email)
        admin = Spree::User.create(:password => password,
                            :password_confirmation => password,
                            :email => email,
                            :login => email)
        role = Spree::Role.find_or_create_by name: "admin"
        admin.spree_roles << role
        admin.save
      end
    end
  end

end
