require 'zip'

class PagesController < ApplicationController
  def index
    @generated_count = REDIS[:generated_count]
  end

  def download
    package = generate_package(
      url:         params[:url],
      name:        params[:name],
      description: params[:description],
      key:         SecureRandom.hex(16)
    )

    send_data package, filename: "#{params[:name]}-#{Time.now.to_i}.zip"
  end

  # TODO cleanup code
  def generate_package(package_data)

    image = nil
    if params[:icon]
      image = MiniMagick::Image.read(params[:icon])
      short_side = [image[:width], image[:height]].min
      image.combine_options do |c|
        c.gravity :center
        c.crop    "#{short_side}x#{short_side}+0+0"
      end
      image.format "png"
    end

    @pkg = package_data

    stringio = Zip::OutputStream::write_buffer do |zio|
      zio.put_next_entry("pkg/html/window.html")
      zio.write erb("html/window.html.erb")

      zio.put_next_entry("pkg/image/icon_128.png")
      if image
        image.resize "128x128"
        zio.write image.to_blob
      else
        zio.write file('image/icon_128.png')
      end

      zio.put_next_entry("pkg/image/icon_16.png")
      if image
        image.resize "16x16"
        zio.write image.to_blob
      else
        zio.write file('image/icon_16.png')
      end

      zio.put_next_entry("pkg/js/background.js")
      zio.write file('js/background.js')

      zio.put_next_entry("pkg/js/window.js")
      zio.write file('js/window.js')

      zio.put_next_entry("pkg/manifest.json")
      zio.write erb("manifest.json.erb")

    end

    REDIS.incr :generated_count

    stringio.rewind
    stringio.sysread
  end

private

  def erb(subpath)
    ERB.new(File.open(template(subpath)).read).result(binding)
  end

  def file(subpath)
    File.open(template(subpath)).read
  end

  def template(subpath)
    "#{Rails.root}/template/#{subpath}"
  end
end
