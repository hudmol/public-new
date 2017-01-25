module Plugins

  def self.init
    init_config
    init_plugins
  end

  def self.init_config
    # any plugins?
    return if all.empty?

    # load them up!

    # controllers
    ArchivesspacePublic::Application.config.paths["app/controllers"].concat(find_directories("public/controllers"))

    # locales
    find_directories.map{|plugin_dir| File.join(plugin_dir, 'public', 'locales')}.reject { |dir| !Dir.exist?(dir) }.each do |locales_override_directory|
      ArchivesspacePublic::Application.config.i18n.load_path += Dir[File.join(locales_override_directory, '**' , '*.{rb,yml}')]
    end

    # assets (Development only)
    if Rails.env.development?
      find_directories.map{|local_dir| File.join(local_dir, 'public', 'assets')}.reject { |dir| !Dir.exist?(dir) }.each do |static_directory|
        ArchivesspacePublic::Application.config.assets.paths.unshift(static_directory)
      end
    end
  end

  def self.init_plugins
    find_directories('public').each do |dir|
      init_file = File.join(dir, "plugin_init.rb")
      if File.exist?(init_file)
        load init_file
      end
    end
  end

  def self.init_template_overrides(controller)
    find_directories.map{|plugin_dir| File.join(plugin_dir, 'public', 'views')}.reject { |dir| !Dir.exist?(dir) }.each do |template_override_directory|
      controller.prepend_view_path(template_override_directory)
    end
  end

  def self.find_directories(base = nil)
    Array(all).map { |plugin| File.join(*[base_directory, "plugins", plugin, base].compact) }
  end

  def self.all
    AppConfig[:plugins] || []
  end

  def self.base_directory
    [java.lang.System.get_property("ASPACE_LAUNCHER_BASE"),
     java.lang.System.get_property("catalina.base"),
     File.join(Rails.root, "..","..")].find {|dir|
      dir && Dir.exist?(dir)
    }
  end

  def self.extend_aspace_routes(routes_file)
    ArchivesspacePublic::Application.config.paths['config/routes.rb'].concat([routes_file])
  end

  def self.add_menu_item(path, label, position = nil)
    ArchivesspacePublic::Application.config.after_initialize do
      PublicNewDefaults::add_menu_item(path, label, position)
    end
  end
end
