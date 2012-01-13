require 'rubygems'
require 'active_record'

# Functional prototype of automatic create/build on a has_one relationship.
# TODO: needs to be loaded before cache_fu extensions.
module HasOneAutocreate
  # TODO: alias_method_chainize these
  module ClassMethods
    def has_one(*args)
      options = args.extract_options!
      autocreate = options.delete(:autocreate)
      autobuild = options.delete(:autobuild)
      args << options
      super(*args)
      
      if autocreate
        reflections[args.first].send "autocreate=", autocreate
      end
      if autobuild
        reflections[args.first].send "autobuild=", autobuild
      end
    end
  end
  
  module InstanceMethods
    # TODO: Move to find_target once we're in front of cache_fu.
    def reload
      value = find_target
      if value
        @target = value
      elsif method = @reflection.send(:autocreate)
        @target = 
          case method
            when true
              create!
            when Symbol, String
              self.send(method)
            when false
              # nop
            else
              # default
              # ActiveRecord::Associations::HasOneAssociation.autocreate
          end
      elsif method = @reflection.send(:autobuild)
        @target = 
          case method
            when true
              build
            when Symbol, String
              self.send(method)
            when false
              # nop
            else
              # default
              # ActiveRecord::Associations::HasOneAssociation.autobuild
          end
      end
      loaded
    end
  end
end

ActiveRecord::Base.extend HasOneAutocreate::ClassMethods
ActiveRecord::Associations::HasOneAssociation.send :include, HasOneAutocreate::InstanceMethods
ActiveRecord::Reflection::AssociationReflection.send :attr_accessor, :autocreate
