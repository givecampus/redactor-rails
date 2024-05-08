class RedactorRails::PicturesController < ApplicationController
  before_action :redactor_authenticate_user!

  def index
    @pictures = RedactorRails.picture_model.where(
        RedactorRails.picture_model.new.respond_to?(RedactorRails.devise_user) ? { RedactorRails.devise_user_key => redactor_current_user.id } : { })
    render :json => @pictures.to_json
  end

  def create
    if params[:version_4].present?
      # Redactor 4
      process_version_4_picture
    else
      # Legacy Redactor
      process_version_2_picture
    end

  end

  private

  def process_version_4_picture
    files = params[:file]
    results = {}
    file_counter = 0

    files.each do |file|
      @picture = RedactorRails.picture_model.new
      attach_picture(file)

      if @picture.save
        file_counter += 1
        results["file-#{file_counter}"] = {
          id: SecureRandom.uuid,
          url: @picture.url(:content)
        }
      end
    end

    render json: results
  rescue StandardError => e
    render json: { error: true, message: e.message }
  end

  def process_version_2_picture
    @picture = RedactorRails.picture_model.new

    file = params[:file]
    attach_picture(file)

    if @picture.save
      render json: { url: @picture.url(:content) }
    else
      render json: { error: @picture.errors }
    end
  end

  def attach_picture(file)
    @picture.data = RedactorRails::Http.normalize_param(file, request)
    if @picture.has_attribute?(:"#{RedactorRails.devise_user_key}")
      @picture.send("#{RedactorRails.devise_user}=", redactor_current_user)
      @picture.assetable = redactor_current_user
    end
  end

  def redactor_authenticate_user!
    if RedactorRails.picture_model.new.has_attribute?(RedactorRails.devise_user)
      super
    end
  end
end
