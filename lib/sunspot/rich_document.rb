module Sunspot

  class RichDocument < RSolr::Xml::Document
    include Enumerable

    def contains_attachment?
      @fields.each do |field|
        if field.name.to_s.include?("_attachment") && field.value.present?
          return true
        end
      end
      return false
    end

    def add(connection)
      params = {
        :wt => :ruby,
        :uprefix => 'ignored_',   # ignore all unknown fields generated by Tika
        'idx.attr' => false       # don't index any attributes, unless explicitly mapped
      }

      data = nil

      @fields.each do |f|
        if f.name.to_s.include?("_attachment") and f.value.present?
          data = open(f.value).read rescue ""
          params['fmap.content'] = f.name
        else
          param_name = "literal.#{f.name.to_s}"
          params[param_name] = [] unless params.has_key?(param_name)
          params[param_name] << f.value
        end
        if f.attrs[:boost]
          params["boost.#{f.name.to_s}"] = f.attrs[:boost]
        end
      end

      connection.send_and_receive('update/extract', 
        { :method => :post, 
          :params => params.merge({:commit => true}), 
          :data => data}, 
          :headers => {"Content-Type" => ""}
        })
    end
  end
end