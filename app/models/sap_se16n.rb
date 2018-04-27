class SapSe16n < ActiveRecord::Base

  STATUS = {
      W: '等待',
      Y: '完成',
      N: '錯誤',
      C: '取消'
  }


  def self.create_transaction(table_name, action_type, selections, attributes)
    sap = SapSe16n.new
    sap.action_type = action_type
    attributes.keys.each do |key|
      if sap.attribute_keys.nil? or sap.attribute_keys.empty?
        sap.attribute_keys = key
        sap.attribute_values = attributes[key]
      else
        sap.attribute_keys = "#{sap.attribute_keys}|#{key}"
        sap.attribute_values = "#{sap.attribute_values}|#{attributes[key]}"
      end
    end
    selections.keys.each do |key|
      if sap.selection_keys.nil? or sap.selection_keys.empty?
        sap.selection_keys = key
        sap.selection_values = selections[key]
      else
        sap.selection_keys = "#{sap.selection_keys}|#{key}"
        sap.selection_values = "#{sap.selection_values}|#{selections[key]}"
      end
    end
    sap.status = 'W'
    sap.table_name = table_name
    sap.jobq = '1'
    sap.save!
  end

  def self.create_job(table_name, action_type, selections, attributes, jobq)
    sap = SapSe16n.new
    sap.action_type = action_type
    attributes.keys.each do |key|
      if sap.attribute_keys.nil? or sap.attribute_keys.empty?
        sap.attribute_keys = key
        sap.attribute_values = attributes[key]
      else
        sap.attribute_keys = "#{sap.attribute_keys}|#{key}"
        sap.attribute_values = "#{sap.attribute_values}|#{attributes[key]}"
      end
    end
    selections.keys.each do |key|
      if sap.selection_keys.nil? or sap.selection_keys.empty?
        sap.selection_keys = key
        sap.selection_values = selections[key]
      else
        sap.selection_keys = "#{sap.selection_keys}|#{key}"
        sap.selection_values = "#{sap.selection_values}|#{selections[key]}"
      end
    end
    sap.status = 'W'
    sap.table_name = table_name
    sap.jobq = jobq || '1'
    sap.save!
  end

end
