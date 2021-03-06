module LipsiaSoft
  # LisiaSoft::AccessControl, permit to manage, backend, and frontend access.
  # You can define on the fly, roles access, for example:
  # 
  #   LipsiaSoft::AccessControl.map :require => [ :administrator, :manager, :customer ]  do |map|
  #     # Shared Permission
  #     map.permission "backend/base"
  #     # Module Permission
  #     map.project_module :accounts, "backend/accounts" do |project|
  #       project.menu :list, { :action => :index }, :class => "icon-no-group"
  #       project.menu :new,  { :action => :new }, :class => "icon-new"
  #     end
  # 
  #   end
  # 
  #   LipsiaSoft::AccessControl.map :require => :customer do |map|
  #     # Shared Permission
  #     map.permission "frontend/cart"
  #     # Module Permission
  #     map.project_module :store, "frontend/store" do |map|
  #       map.menu :add, { :cart => :add }, :class => "icon-no-group"
  #       map.menu :list,  { :cart => :list }, :class => "icon-no-group"
  #     end  
  #   end                                                                    
  # 
  # So the when you do:
  #
  #   LipsiaSoft::AccessControl.roles
  #   # => [:administrator, :manager, :customer]
  #   
  #   LipsiaSoft::AccessControl.project_modules(:customer)
  #   # => [#<LipsiaSoft::AccessControl::ProjectModule:0x254a9c8 @controller="backend/accounts", @name=:accounts, @menus=[#<LipsiaSoft::AccessControl::Menu:0x254a928 @url={:action=>:index}, @name=:list, @options={:class=>"icon-no-group"}>, #<LipsiaSoft::AccessControl::Menu:0x254a8d8 @url={:action=>:new}, @name=:new, @options={:class=>"icon-new"}>]>, #<LipsiaSoft::AccessControl::ProjectModule:0x254a84c @controller="frontend/store", @name=:store, @menus=[#<LipsiaSoft::AccessControl::Menu:0x254a7d4 @url={:cart=>:add}, @name=:add, @options={}>, #<LipsiaSoft::AccessControl::Menu:0x254a798 @url={:cart=>:list}, @name=:list, @options={}>]>]
  #
  #   LipsiaSoft::AccessControl.allowed_controllers(:customer)
  #   => ["backend/base", "backend/accounts", "frontend/cart", "frontend/store"]
  #  
  # If in your controller there is *login_required* our Authenticated System verify the allowed_controllers for the account role (Ex: :customer),
  # if not satisfed you will be redirected to login page.
  #
  # An account have two columns, role, that is a string, and project_modules, that is an array (with serialize)
  # 
  # For example, whe can decide that an Account with role :customers can see only, the module project :store.  
  module AccessControl
    class << self
      def map(role)
        @mappers ||= []
        @roles ||= []
        mapper = Mapper.new(role)
        yield mapper
        @mappers << mapper
        @roles.concat(mapper.roles)
      end
      
      def project_modules(role)
        project_modules = []
        mappers(role).each { |m| project_modules.concat(m.project_modules) }  
        return project_modules.uniq.compact
      end
      
      def project_module(role, name)
        project_modules(role).find { |p| p.name == name }
      end
    
      def roles
        return @roles.uniq.compact
      end
      
      def human_roles
        return roles.collect(&:to_s).collect(&:humanize)
      end
      
      def allowed_controllers(role, project_modules)
        controllers = []
        mappers(role).each { |m| controllers.concat(m.controllers) }
        project_modules.each { |m| controllers.concat(project_module(role, m).controllers) }
        return controllers.uniq.compact
      end
      
    private
      def mappers(role)
        @mappers.select { |m| m.roles.include?(role.to_s.downcase.to_sym) }
      end
    end
    
    class Mapper
      attr_reader :project_modules, :roles
      
      def initialize(hash)
        @roles = hash[:require].is_a?(Array) ? hash[:require].collect { |r| r.to_s.downcase.to_sym } : [hash[:require].to_s.downcase.to_sym]
        @project_modules = []
        @controllers = []
      end
      
      def project_module(name, controller)
        project_module = ProjectModule.new(name, controller)
        yield project_module
        @project_modules << project_module
        #@controllers << controller
      end
      
      def permission(controller)
        @controllers << controller
      end
      
      def controllers
        return @controllers.uniq.compact
      end
    end
    
    class ProjectModule
      attr_reader :name, :menus, :controllers
      
      def initialize(name, controller=nil)
        @name = name
        @controllers = [] 
        @controllers << controller
        @menus = []
      end
      
      def menu(name, url, options={})
        if url.is_a?(Hash) 
          url[:controller].nil? ? url[:controller] = @controllers.first : @controllers << url[:controller]
        end
        @menus << Menu.new(name, url, options)
      end
      
      def human_name
        return @name.to_s.humanize
      end
      
      def uid
        @name.to_s.downcase.gsub(/[^a-z0-9]+/, '').gsub(/-+$/, '').gsub(/^-+$/, '')
      end
    end
    
    class Menu
      attr_reader :name, :options, :url
      
      def initialize(name, url, options)
        @name = name
        @options = options
        @url = url
      end
      
      def human_name
        return @name.to_s.humanize
      end
      
      def uid
        @name.to_s.downcase.gsub(/[^a-z0-9]+/, '').gsub(/-+$/, '').gsub(/^-+$/, '')
      end
    end

  end
end
