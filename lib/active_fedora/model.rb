SOLR_DOCUMENT_ID = "id" unless defined?(SOLR_DOCUMENT_ID)

module ActiveFedora
  # = ActiveFedora
  # This module mixes various methods into the including class,
  # much in the way ActiveRecord does.  
  module Model 
    extend ActiveSupport::Concern

    included do
      class_attribute  :solr_query_handler
      self.solr_query_handler = 'standard'
    end
    
    # Takes a Fedora URI for a cModel and returns classname, namespace
    def self.classname_from_uri(uri)
      local_path = uri.split('/')[1]
      parts = local_path.split(':')
      return parts[-1].split(/_/).map(&:camelize).join('::'), parts[0]
    end

    # Takes a Fedora URI for a cModel, and returns a 
    # corresponding Model if available
    # This method should reverse ClassMethods#to_class_uri
    # @return [Class, False] the class of the model or false, if it does not exist
    def self.from_class_uri(uri)
      model_value, pid_ns = classname_from_uri(uri)
      raise "model URI incorrectly formatted: #{uri}" unless model_value

      unless class_exists?(model_value)
        logger.warn "#{model_value} is not a real class"
        return false
      end
      if model_value.include?("::")
        result = eval(model_value)
      else
        result = Kernel.const_get(model_value)
      end
      unless result.nil?
        model_ns = (result.respond_to? :pid_namespace) ? result.pid_namespace : ContentModel::CMODEL_NAMESPACE
        if model_ns != pid_ns
          logger.warn "Model class namespace '#{model_ns}' does not match uri: '#{uri}'"
        end
      end
      result
    end

    module ClassMethods
      # Returns a suitable uri object for :has_model
      # Should reverse Model#from_class_uri
      def to_class_uri(attrs = {})
        unless self.respond_to? :pid_suffix
          pid_suffix = attrs.has_key?(:pid_suffix) ? attrs[:pid_suffix] : ContentModel::CMODEL_PID_SUFFIX
        else
          pid_suffix = self.pid_suffix
        end
        unless self.respond_to? :pid_namespace
          namespace = attrs.has_key?(:namespace) ? attrs[:namespace] : ContentModel::CMODEL_NAMESPACE   
        else
          namespace = self.pid_namespace
        end
        "info:fedora/#{namespace}:#{ContentModel.sanitized_class_name(self)}#{pid_suffix}" 
      end
      
    end

    private 
    
      def self.class_exists?(class_name)
        klass = class_name.constantize
        return klass.is_a?(Class)
      rescue NameError
        return false
      end
    
  end
end
