#!/usr/bin/ruby

require 'rubygems'
require 'rexml/document'
require 'erb'
require 'tmpdir'
require 'fileutils'

class BGProj
	attr_accessor :gatt_xml_file
	attr_accessor :hardware_xml_file
	attr_accessor :config_xml_file
	attr_accessor :script_file

	attr_accessor :image_file
	attr_accessor :ota_image_file
end

class GATT
	attr_reader :gatt_doc
	attr_reader :gap_svc
	attr_reader :dev_info_svc

	attr_reader :bundle_name
	attr_reader :hw_id
	attr_reader :hw_version
	attr_reader :fw_id
	attr_reader :fw_version

	def service_element_with(uuid)
		gatt_doc.elements["configuration/service[translate(@uuid,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')='#{uuid.downcase}']"]
	end

	def initialize(gatt_xml_file)
		@gatt_doc = REXML::Document.new(File.new(gatt_xml_file))

		@gap_svc      = service_element_with('1800')
		@dev_info_svc = service_element_with('180a')

		@bundle_name = value_for_uuid(gap_svc,'2a00')
		@bundle_name = "#{bundle_name} Firmware"

		@hw_id      = value_for_uuid(dev_info_svc, '2a24')
		@hw_version = value_for_uuid(dev_info_svc, '2a27')
		@fw_id      = value_for_uuid(dev_info_svc, '5d5b1dd0-925c-4826-87f2-e2b8cb7a50a6')
		@fw_version = value_for_uuid(dev_info_svc, '2a26')
	end

	def value_for_uuid(service, uuid)
		xpath = "characteristic[translate(@uuid,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')='#{uuid.downcase}']/value"

		service.elements[xpath].text
	end
end

class Packager

	attr_reader :folder
	attr_reader :gatt
	attr_reader :icons

	def etc_folder
		@etc_folder ||= File.join(File.expand_path(File.dirname(__FILE__)), 'etc')
	end

	def bgproj_file
		@bgproj_file ||= begin
			projs = Dir[File.join(folder,'*.bgproj')]
			if projs.size > 0
				projs[0]
			else
				nil
			end
		end
	end

	def icons
		@icons ||= begin
			icons = Dir[File.join(folder,'icon*.png')]
			if icons.nil? || icons.size < 1
				icons = [ File.join(etc_folder, 'default_icon.png') ]
			end
		end
	end

	def bgproj
		@bgproj ||= begin
			bgproj = BGProj.new
			bgproj_dir = File.dirname(bgproj_file)
			xml = REXML::Document.new(File.new(bgproj_file))

			bgproj.gatt_xml_file     = File.join bgproj_dir, xml.elements["project/gatt"].attributes['in']
			bgproj.hardware_xml_file = File.join bgproj_dir, xml.elements["project/hardware"].attributes['in']
			bgproj.config_xml_file   = File.join bgproj_dir, xml.elements["project/config"].attributes['in']
			bgproj.script_file       = File.join bgproj_dir, xml.elements["project/script"].attributes['in']

			bgproj.image_file        = File.join bgproj_dir, xml.elements["project/image"].attributes['out']
			bgproj.ota_image_file    = File.join bgproj_dir, xml.elements["project/ota"].attributes['out']

			bgproj
		end
	end

	def firmware_plist_erb
		path = File.join(etc_folder, 'firmware.plist.erb')
		ERB.new(File.new(path).read, nil, '-')
	end

	def run!(arg)
		@folder = File.expand_path(arg)

		@gatt = GATT.new(bgproj.gatt_xml_file)

		plist = firmware_plist_erb.result(binding)

		Dir.mktmpdir do |dir|
			package_path = File.join(dir, 'BLEKitFirmware')
			FileUtils.mkdir_p(package_path)

			File.open(File.join(package_path, 'info.plist'),'w+') { |f| f.write(plist) }

			FileUtils.cp_r(bgproj.ota_image_file, File.join(package_path, 'firmware.bin'))

			icon_index = 1
			icons.each do |icon_file|
				FileUtils.cp(icon_file, File.join(package_path, "icon#{icon_index}.png"))
				icon_index += 1
			end

			FileUtils.cd(dir) do
				`zip -qr BLEKitFirmware.zip BLEKitFirmware`
			end
			package_zip = File.join(dir, 'BLEKitFirmware.zip')

			ts = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
			dst_dir  = File.dirname(bgproj.ota_image_file || bgproj.image_file)
			dst_file = File.join(dst_dir, "#{gatt.hw_id}_#{gatt.hw_version}_#{gatt.fw_id}_#{gatt.fw_version}_#{ts}.zip".gsub(/[^a-zA-Z0-9\-\.]/,'_'))

			FileUtils.cp_r(package_zip, dst_file)
		end
	end

	
end

Packager.new.run!(ARGV.shift)