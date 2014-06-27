require 'yaml'
require 'ostruct'


class Kick

  def initialize
    file = File.join(Dir.pwd, 'kick.spec')
    @build_settings = OpenStruct.new(YAML.load_file(file))
    puts @build_settings
    @base_name = @build_settings.base_name
    @provisioning_profile_in_developer_program_name = @build_settings.provisioning_profile_name
    @provisioning_profile_name = @provisioning_profile_in_developer_program_name.gsub(/ /, '_')
  end

  def clean
    system("rm #{@base_name}.ipa")
    system("rm #{@base_name}.app.dSYM.zip")
    system("rm #{@provisioning_profile_name}.mobileprovision")
  end

  def update_mobileprovision
    developer_portal_team_id = @build_settings.developer_portal_team_id
    command_info = "ios profiles:download \"#{@provisioning_profile_in_developer_program_name}\" --team #{developer_portal_team_id}"
    system(command_info)
  end

  def info
    command_info = "ipa info #{@base_name}.ipa"
    system(command_info)
  end

  def build

    self.clean
    self.update_mobileprovision

    computer_name = %x[scutil --get ComputerName].strip
    puts "computer_name: #{computer_name}"
    code_signing_identity = @build_settings.code_signing_identity[computer_name]
    scheme = @build_settings.scheme

    command_build = "ipa build -m #{@provisioning_profile_name}.mobileprovision -i \"#{code_signing_identity}\" -s \"#{scheme}\" --verbose"

    puts command_build

    system(command_build)
    puts 'build completed'

    self.info

  end

  def dist(distribution_list=nil)

    self.build

    notes = @build_settings.notes
    api_token = @build_settings.api_token
    team_token = @build_settings.team_token
    if distribution_list == nil
      distribution_list = @build_settings.distribution_list
    end

    #puts "Enter your notes:\n"
    #notes = gets

    command_deploy = "ipa distribute:testflight -a #{api_token} -T #{team_token} -m '#{notes}' -l #{distribution_list} --notify --verbose"

    system(command_deploy)

    puts 'deploy completed'

    self.info
    self.clean

  end

end