class RedactorRails::DocumentsController < ApplicationController
  before_action :redactor_authenticate_user!

  def index
    @documents = RedactorRails.document_model.where(
        RedactorRails.document_model.new.respond_to?(RedactorRails.devise_user) ? { RedactorRails.devise_user_key => redactor_current_user.id } : { })
    render :json => @documents.to_json
  end

  def create
    if params[:version_4].present?
      # Redactor 4
      process_version_4_document
    else
      # Legacy Redactor
      process_version_2_document
    end

  end

  private

  def process_version_4_document
    files = params[:file]
    results = {}
    file_counter = 0

    files.each do |file|
      @document = RedactorRails.document_model.new
      attach_document(file)

      if @document.save
        file_counter += 1
        results["file-#{file_counter}"] = {
          id: SecureRandom.uuid,
          name: file.original_filename,
          url: @document.url
        }
      end
    end

    render json: results
  rescue StandardError => e
    render json: { error: true, message: e.message }
  end

  def process_version_2_document
    @document = RedactorRails.document_model.new
    file = params[:file]
    attach_document(file)

    if @document.save
      render json: { url: @document.url, filename: @document.filename }
    else
      render json: { error: @document.errors }
    end
  end

  def attach_document(file)
    @document.data = RedactorRails::Http.normalize_param(file, request)
    if @document.has_attribute?(:"#{RedactorRails.devise_user_key}")
      @document.send("#{RedactorRails.devise_user}=", redactor_current_user)
      @document.assetable = redactor_current_user
    end
  end

  def redactor_authenticate_user!
    if RedactorRails.document_model.new.has_attribute?(RedactorRails.devise_user)
      super
    end
  end
end
