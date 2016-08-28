function string.split(str, delimiter)
	if str==nil or str=='' or delimiter==nil then
		return nil
	end
	
    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

table.icontains = function(tbl, obj, func)
	if func then
		for i,v in ipairs(tbl) do
	        if func(v,obj) then
	            return i
	        end
	    end
	else
	    for i,v in ipairs(tbl) do
	        if v == obj then
	            return i
	        end
	    end
	end
    return nil
end