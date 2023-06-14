export @vf


mutable struct VueFor
  listname::String
  itervar::String
  value
  attrs::Dict{String, Any}
  cols::Union{Nothing,Float64}
  render_func::Union{Nothing,Function}
end

function VueFor( listname::String, itervar::String, value, attrs::Dict )
  cols = get( attrs, "cols", nothing )
  delete!( attrs, "cols" )
  render_func = get( attrs, "render_func", nothing )
  delete!( attrs, "render_func" )
  VueFor( listname, itervar, value, attrs, cols, render_func )
end


macro vf( varname, listname, itervar, value, args... )
  @assert varname isa Symbol "1st arg should be Variable name"
  @assert listname isa Union{Symbol, AbstractString} "2nd arg should be list name"
  @assert itervar isa Union{Symbol, AbstractString} "3rd arg should be iteration variable name"

  newargs = treat_kwargs(args)
  newargs = "Dict($(join( newargs, "," )))"
  value isa AbstractString && (value = "\"$value\"")
  newexpr = Meta.parse( """VueJS.VueFor("$listname", "$itervar", $value, $newargs)""" )

  quote
    $(esc(varname)) = $(esc(newexpr))
  end
end
