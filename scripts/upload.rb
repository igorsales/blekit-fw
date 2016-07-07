#!/usr/bin/ruby

class Uploader
	def auth_token_sh_file
		@auth_token_sh_file ||= File.join(File.expand_path(File.dirname(__FILE__)),'tmp','set_auth_token.sh')
	end

	def auth_token
		@auth_token ||= `source #{auth_token_sh_file}; echo ${BLEKIT_AUTH_TOKEN}`.gsub(/[\r\n]+$/,'')
	end

	def upload(file)
		system("curl -vvv -X POST -F firmware=@#{file} -H 'X-BLEKIT-AUTH: #{auth_token}' https://blekit.igorsales.ca/loads")
	end

	def run!(file)
		raise "No file specified" unless file

		upload(file)
	end
end

Uploader.new.run!(ARGV.shift)