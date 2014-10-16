module ActiveFedora
  module ConditionsToSolrQueryBuilder
    module_function
    def call(conditions, model_class = nil)
      case conditions
      when Hash
        build_query([create_query_from_hash(conditions, model_class)], model_class)
      when String
        build_query(["(#{conditions})"], model_class)
      else
        build_query(conditions, model_class)
      end
    end

    def build_query(conditions, model_class)
      clauses = search_model_clause(model_class) ?  [search_model_clause(model_class)] : []
      clauses += conditions.reject{|c| c.blank?}
      return "*:*" if clauses.empty?
      clauses.compact.join(" AND ")
    end
    private_class_method :build_query

    def create_query_from_hash(conditions, model_class)
      conditions.map {|key,value| condition_to_clauses(key, value, model_class)}.compact.join(" AND ")
    end

    def condition_to_clauses(key, value, model_class)
      unless value.nil?
        # if the key is a property name, turn it into a solr field
        if model_class && model_class.defined_attributes.key?(key)
          # TODO Check to see if `key' is a possible solr field for this class, if it isn't try :searchable instead
          key = ActiveFedora::SolrService.solr_name(key, :stored_searchable, type: :string)
        end

        if value.empty?
          "-#{key}:['' TO *]"
        elsif value.is_a? Array
          value.map { |val| "#{key}:#{RSolr.escape(val)}" }
        else
          key = SOLR_DOCUMENT_ID if (key === :id || key === :pid)
          "#{key}:#{RSolr.escape(value)}"
        end
      end
    end
    private_class_method :condition_to_clauses

    # Return the solr clause that queries for this type of class
    def search_model_clause(model_class)
      unless model_class == ActiveFedora::Base
        return ActiveFedora::SolrService.construct_query_for_rel(:has_model => model_class.to_class_uri)
      end
    end
    private_class_method :condition_to_clauses

  end
end
