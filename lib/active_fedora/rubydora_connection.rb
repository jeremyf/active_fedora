require 'singleton'
require 'rubydora'

module ActiveFedora
  class RubydoraConnection
    include Singleton
    
    attr_accessor :options

    def self.connect(params={})
      params = params.dup
      if params.kind_of? String
        u = URI.parse params
        params = {}
        params[:user] = u.user
        params[:password] = u.password
        params[:url] = "#{u.scheme}://#{u.host}:#{u.port}#{u.path}"
      end
      instance = self.instance
      force = params.delete(:force)
      instance.options = params
      instance.connect force
      instance
    end

    def connection
      return @connection if @connection
      ActiveFedora.load_configs
      ActiveFedora::RubydoraConnection.connect(ActiveFedora.fedora_config[:url])
      @connection
    end
    

    def connect(force=false)
      return unless @connection.nil? or force
      allowable_options = [:url, :user, :password, :timeout, :open_timeout, :ssl_client_cert, :ssl_client_key]
      client_options = options.reject { |k,v| not allowable_options.include?(k) }
      #puts "CLIENT OPTS #{client_options.inspect}"
      @connection = Rubydora.connect client_options
    end

    def nextid(attrs={})
      d = REXML::Document.new(connection.next_pid(:namespace=>attrs[:namespace]))
      d.elements['//pid'].text
    end

    def find_model(pid, klass)
      klass.allocate.init_with(DigitalObject.find(klass, pid))
    end

  end
end
