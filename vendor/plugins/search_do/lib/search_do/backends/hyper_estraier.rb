#!/usr/bin/env ruby
require 'vendor/estraierpure'
require 'search_do/utils'

module SearchDo
  module Backends
    class HyperEstraier
      SYSTEM_ATTRIBUTES = %w( uri digest cdate mdate adate title author type lang genre size weight misc )

      attr_reader :connection
      attr_accessor :node_name

      DEFAULT_CONFIG = {
        'host' => 'localhost',
        'port' => 1978,
        'user' => 'admin',
        'password' => 'admin',
        'backend' => 'hyper_estraier',
      }.freeze

      # FIXME use URI
      def initialize(ar_class, config = {})
        @ar_class = ar_class
        config = DEFAULT_CONFIG.merge(config)
        self.node_name = calculate_node_name(config)

        @connection = EstraierPure::Node.new
        @connection.set_url("http://#{config['host']}:#{config['port']}/node/#{self.node_name}")
        @connection.set_auth(config['user'], config['password'])
      end

      def index
        cond = EstraierPure::Condition::new
        cond.add_attr("db_id NUMGT 0")
        result = raw_search(cond, 1)
        result ? result.docs : []
      end

      def search_by_db_id(id)
        cond = EstraierPure::Condition::new
        cond.set_options(EstraierPure::Condition::SIMPLE | EstraierPure::Condition::USUAL)
        cond.add_attr("db_id NUMEQ #{id}")

        result = raw_search(cond, 1)
        return nil if result.nil? || result.doc_num.zero?
        result.first_doc
      end

      def count(query, options={})
        cond = build_fulltext_condition(query, options.merge(:count=>true))
        benchmark("  #{@ar_class.to_s} count fulltext, Cond: #{cond.to_s}") do
          r = raw_search(cond, 1);
          r.doc_num rescue 0
        end
      end

      def search_all(query, options = {})
        cond = build_fulltext_condition(query, options)

        benchmark("  #{@ar_class.to_s} fulltext search, Cond: #{cond.to_s}") do
          result = raw_search(cond, 1);
          result ? result.docs : []
        end
      end

      def search_all_ids(query, options ={})
        search_all(query, options).map{|doc| doc.attr("db_id").to_i }
      end

      def add_to_index(texts, attrs)
        doc = EstraierPure::Document::new
        texts.reject(&:blank?).each{|t| doc.add_text(textise(t)) }
        attrs.reject{|k,v| v.blank?}.each{|k,v| doc.add_attr(attribute_name(k), textise(v)) }

        log = "  #{@ar_class.name} [##{attrs["db_id"]}] Adding to index"
        benchmark(log){ @connection.put_doc(doc) }
      end

      def remove_from_index(db_id)
        return unless doc = search_by_db_id(db_id)
        log = "  #{@ar_class.name} [##{db_id}] Removing from index"
        benchmark(log){ delete_from_index(doc) }
      end

      def clear_index!
        benchmark("  Deleting all index"){ index.each { |d| delete_from_index(d) } }
      end

    private

      def raw_search(cond, num)
        @connection.search(cond, num)
      end

      def textise(obj) # :nodoc:
        case obj
        when Time then obj.iso8601
        when Date, DateTime then obj.to_s # Date#to_s equals iso8601
        else obj.to_s
        end
      end

      def build_fulltext_condition(query, options = {})
        options = {:limit => 100, :offset => 0}.merge(options)
        # options.assert_valid_keys(VALID_FULLTEXT_OPTIONS)

        cond = EstraierPure::Condition::new
        cond.set_options(EstraierPure::Condition::SIMPLE | EstraierPure::Condition::USUAL)

        cond.set_phrase Utils.tokenize_query(query)

        [options[:attributes]].flatten.reject { |a| a.blank? }.each do |attr|
          cond.add_attr attr
        end
        cond.set_max   options[:limit] unless options[:count]
        cond.set_skip  options[:offset]
        cond.set_order translate_order_to_he(options[:order]) if options[:order]
        return cond
      end

      def translate_order_to_he(order)
        order = order.to_s.downcase.strip
        case order
          when /^updated_at[ ]{0,1}/,/^updated_on[ ]{0,1}/ then "@mdate " + numd_or_numa(order)
          when /^created_at[ ]{0,1}/,/^created_on[ ]{0,1}/ then "@cdate " + numd_or_numa(order)
          when /^id[ ]{0,1}/ then "db_id " + numd_or_numa(order)
          else order
        end
      end

      def numd_or_numa(order)
        order =~ / asc$/ ? "NUMA" : "NUMD"
      end

      def delete_from_index(document)
        @connection.out_doc(document.attr('@id'))
      end

      def benchmark(log, &block)
        @ar_class.benchmark(log, &block)
      end

      def calculate_node_name(config)
        #node_prefix = config['node_prefix'] || config['node'] || RAILS_ENV
        #"#{node_prefix}_#{@ar_class.table_name}"
        config['node_prefix'] || config['node'] || RAILS_ENV
      end

      def attribute_name(attribute)
        SYSTEM_ATTRIBUTES.include?(attribute.to_s) ? "@#{attribute}" : "#{attribute}"
      end
    end
  end
end

# call after creating namespace SearchDo::Backends::HyperEstraier
require 'search_do/backends/hyper_estraier/estraier_pure_extention'

