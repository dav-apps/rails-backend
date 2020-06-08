class TableObjectHolder
	attr_reader :obj, :properties, :values

	def initialize(obj)
		@obj = obj
		@properties = Array.new
		@values = Hash.new

		obj.properties.each do |prop|
			@properties.push(prop)
			@values[prop.name] = prop.value
		end
	end
end