class Api::WidgetsController < ApplicationController
  skip_before_action :verify_authenticity_token

  # GET /api/widgets
  def index
    @widgets = Widget.all
    render json: @widgets
  end

  # GET /api/widgets/1
  def show
    @widget = Widget.find(params[:id])
    render json: @widget
  end

  # PATCH/PUT /api/widgets/1
  def update
    @widget = Widget.find(params[:id])
    if params[:widget][:logo_base64].present?
      @widget.logo = decode_logo
    end
    if @widget.update(widget_params)
      render json: @widget
    else
      render json: @widget.errors, status: :unprocessable_entity
    end
  end

  private

  def decode_logo
    regexp = /\Adata:([-\w]+\/[-\w+.]+)?;base64,(.*)/m
    data_uri_parts = params[:widget][:logo_base64].match(regexp) || []
    extension = MIME::Types[data_uri_parts[1]].first.preferred_extension
    file_name = "logo.#{extension}"
    {
      io: StringIO.new(Base64.decode64(data_uri_parts[2])),
      content_type: data_uri_parts[1],
      filename: file_name
    }
  end

  def widget_params
    params.require(:widget).permit(:name, :description, :status, :activation_date, :remove_logo, :updated_by)
  end
end
