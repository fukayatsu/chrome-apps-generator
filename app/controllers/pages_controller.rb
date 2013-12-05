require 'zip'

class PagesController < ApplicationController
  def index
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
    @pkg = package_data

    stringio = Zip::OutputStream::write_buffer do |zio|
      zio.put_next_entry("pkg/html/window.html")
      zio.write erb("html/window.html.erb")

      zio.put_next_entry("pkg/image/icon_128.png")
      zio.write file('image/icon_128.png')

      zio.put_next_entry("pkg/image/icon_16.png")
      zio.write file('image/icon_16.png')

      zio.put_next_entry("pkg/js/background.js")
      zio.write file('js/background.js')

      zio.put_next_entry("pkg/manifest.json")
      zio.write erb("manifest.json.erb")

    end
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
