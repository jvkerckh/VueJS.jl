mutable struct VueHolder

    tag::String
    attrs::Dict{String, Any} 
    elements::Array
    cols::Union{Nothing,Int64}
    render_func::Union{Nothing,Function}
    
    function VueHolder(tag::String,attrs::Dict,elements::Array,cols::Union{Nothing,Int64},render_func::Union{Nothing,Function})
        vueh=new(tag,attrs,elements,cols,render_func)
        
        if haskey(UPDATE_VALIDATION, tag)
            UPDATE_VALIDATION[tag](vueh)
        end
    
        return vueh
    end
    
end

