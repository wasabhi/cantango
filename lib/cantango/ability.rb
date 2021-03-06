require 'cantango/permit_engine/util'

module CanTango
  class Ability
    autoload_modules :Scope, :Cache
    autoload_modules :MasqueradeHelpers, :PermitHelpers, :PermissionHelpers
    autoload_modules :UserHelpers, :RoleHelpers, :CacheHelpers

    include CanCan::Ability

    attr_reader :options, :subject, :session, :candidate

    # Equivalent to a CanCan Ability#initialize call
    # which executes all the permission logic
    def initialize candidate, options = {}
      raise "Candidate must be something!" if !candidate
      @candidate, @options = candidate, options
      @session = options[:session] || {} # seperate session cache for each type of user?

      return if cached_rules?

      clear_rules!
      permit_rules
      execute_engines!

      cache_rules! if caching_on?
    end

    include CanTango::PermitEngine::Util

    def permit_rules
    end

    def clear_rules!
      @rules = []
    end

    def execute_engines!
      each_engine {|engine| engine.new(self).execute! if engine  }
    end

    def each_engine &block
      engines.execution_order.each {|name| yield engines.registered[name] if engines.active? name }
    end

    def engines
      CanTango.config.engines
    end

    def subject
      return candidate.active_user if masquerade_user?
      return candidate.active_account if masquerade_account?
      candidate
    end

    def config
      CanTango.config
    end

    include CacheHelpers
    include MasqueradeHelpers
    include PermissionHelpers
    include PermitHelpers
    include UserHelpers
    include RoleHelpers
  end
end
