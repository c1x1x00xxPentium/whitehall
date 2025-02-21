class Admin::WorldwideOfficesController < Admin::BaseController
  before_action :find_worldwide_organisation
  before_action :find_worldwide_office, only: %i[edit update confirm_destroy destroy]
  extend Admin::HomePageListController
  is_home_page_list_controller_for :offices,
                                   item_type: WorldwideOffice,
                                   redirect_to: ->(container, _item) { [:admin, container, WorldwideOffice] },
                                   params_name: :worldwide_office

  def index; end

  def new
    @worldwide_office = @worldwide_organisation.offices.build
    @worldwide_office.build_contact
    @worldwide_office.contact.contact_numbers.build
  end

  def edit
    @worldwide_office.contact.contact_numbers.build unless @worldwide_office.contact.contact_numbers.any?
  end

  def update
    worldwide_office_params[:service_ids] ||= []
    if @worldwide_office.update(worldwide_office_params)
      handle_show_on_home_page_param
      redirect_to [:admin, @worldwide_organisation, WorldwideOffice], notice: "#{@worldwide_office.title} has been edited"
    else
      @worldwide_office.contact.contact_numbers.build if @worldwide_office.contact.contact_numbers.blank?
      render :edit
    end
  end

  def create
    @worldwide_office = @worldwide_organisation.offices.build(worldwide_office_params)
    if @worldwide_office.save
      handle_show_on_home_page_param
      redirect_to [:admin, @worldwide_organisation, WorldwideOffice], notice: "#{@worldwide_office.title} has been added"
    else
      @worldwide_office.contact.contact_numbers.build if @worldwide_office.contact.contact_numbers.blank?
      render :new
    end
  end

  def reorder
    @reorderable_offices = @worldwide_organisation.home_page_offices
  end

  def confirm_destroy; end

  def destroy
    title = @worldwide_office.title

    if @worldwide_office.destroy
      redirect_to [:admin, @worldwide_organisation, WorldwideOffice], notice: "#{title} has been deleted"
    else
      render :edit
    end
  end

private

  def home_page_list_item
    @worldwide_office
  end

  def home_page_list_container
    @worldwide_organisation
  end

  def find_worldwide_organisation
    @worldwide_organisation = WorldwideOrganisation.friendly.find(params[:worldwide_organisation_id])
  end

  def find_worldwide_office
    @worldwide_office = @worldwide_organisation.offices.find(params[:id])
  end

  def worldwide_office_params
    params.require(:worldwide_office)
          .permit(:worldwide_office_type_id,
                  :show_on_home_page,
                  :access_and_opening_times,
                  service_ids: [],
                  contact_attributes: [
                    :id,
                    :title,
                    :contact_type_id,
                    :comments,
                    :recipient,
                    :street_address,
                    :locality,
                    :region,
                    :postal_code,
                    :country_id,
                    :email,
                    :contact_form_url,
                    { contact_numbers_attributes: %i[id label number _destroy] },
                  ])
  end
end
