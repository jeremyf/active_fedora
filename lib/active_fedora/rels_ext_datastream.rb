require 'solrizer/field_name_mapper'

module ActiveFedora
  class RelsExtDatastream < Datastream
    
    include ActiveFedora::SemanticNode
    include Solrizer::FieldNameMapper
    
    
    def initialize(attrs=nil)
      super
      self.dsid = "RELS-EXT"
    end
    
    def save
      if @dirty == true
        self.content = to_rels_ext(self.pid)
      end
      super
    end
      
    def pid=(pid)
      super
      self.blob = <<-EOL
      <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
        <rdf:Description rdf:about="info:fedora/#{pid}">
        </rdf:Description>
      </rdf:RDF>
      EOL
    end
    
    # @tmpl ActiveFedora::MetadataDatastream
    # @node Nokogiri::XML::Node
    def self.from_xml(tmpl, node) 
      # From Fedora 3.3.x to 3.6.x the order of the foxml:datastreamVersion
      # changed. Previously (3.3.x) the versions were listed in date ascending
      # order (i.e. earliest first). In 3.6 this order changed. So instead of
      # leaning on `xpath("./foxml:datastreamVersion[last()]")` or
      # `xpath("./foxml:datastreamVersion[1]")`, I am looking via ruby for the
      # most recent
      node_to_use = nil
      node_to_use_created_at = nil
      node.xpath("./foxml:datastreamVersion").each do |inner_node|
        node_created_at = Time.parse(inner_node.attribute('CREATED').value)
        if node_to_use.nil? || node_created_at > node_to_use_created_at
          node_to_use = inner_node
          node_to_use_created_at = node_created_at
        end
      end
      if node_to_use
        node_to_use.xpath("./foxml:xmlContent/rdf:RDF/rdf:Description/*", {"rdf"=>"http://www.w3.org/1999/02/22-rdf-syntax-ns#", "foxml"=>"info:fedora/fedora-system:def/foxml#"}).each do |f|
          r = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>ActiveFedora::SemanticNode::PREDICATE_MAPPINGS.invert[f.name], :object=>f["resource"])
          tmpl.add_relationship(r)
        end
      end
      tmpl.send(:dirty=, false)
      tmpl
    end
    
    def to_solr(solr_doc = Solr::Document.new)
      self.relationships.each_pair do |subject, predicates|
        if subject == :self || subject == "info:fedora/#{self.pid}"
          predicates.each_pair do |predicate, values|
            values.each do |val|
              solr_doc << Solr::Field.new(solr_name(predicate, :symbol) => val)
            end
          end
        end
      end
      return solr_doc
    end
    
    # ** EXPERIMENTAL **
    # 
    # This is utilized by ActiveFedora::Base.load_instance_from_solr to load 
    # the relationships hash using the Solr document passed in instead of from the RELS-EXT datastream
    # in Fedora.  Utilizes solr_name method (provided by Solrizer::FieldNameMapper) to map solr key to
    # relationship predicate. 
    #
    # ====Warning
    #  Solr must be synchronized with RELS-EXT data in Fedora.
    def from_solr(solr_doc)
      #cycle through all possible predicates
      PREDICATE_MAPPINGS.keys.each do |predicate|
        predicate_symbol = ActiveFedora::SolrService.solr_name(predicate, :symbol)
        value = (solr_doc[predicate_symbol].nil? ? solr_doc[predicate_symbol.to_s]: solr_doc[predicate_symbol]) 
        unless value.nil? 
          if value.is_a? Array
            value.each do |obj|
              r = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>predicate, :object=>obj)
              add_relationship(r)
            end
          else
            r = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>predicate, :object=>value)
            add_relationship(r)
          end
        end
      end
      @load_from_solr = true
    end
  end
end
