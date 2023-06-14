export @vif, @velseif, @velse, @vc


mutable struct VueIf
  value
  firstcond::Bool
  condition::Union{Nothing,String}
end


mutable struct VueCond
  value::Vector{VueIf}

  function VueCond( value )
    @assert value isa Vector{VueIf} "1st argument must be vector of Vue if-else clauses"

    # Find primary if clause
    ifcl = filter( vif -> vif.firstcond, value )
    @assert length(ifcl) == 1 "1st argument must contain exactly one primary Vue if clause"
    ifcl = ifcl[1]

    new_value = vcat( ifcl, filter( vif -> vif.condition isa String && !vif.firstcond, value ) )

    # Find else clauses
    elsecl = findall( vif -> vif.condition isa Nothing, value )
    isempty(elsecl) && return new(new_value)

    collapsed_else = VueIf( getfield.( value[elsecl], :value ), false, nothing )
    push!( new_value, collapsed_else )
    new(new_value)
  end
end


macro vif( varname, condition, value )
  @assert varname isa Symbol "1st arg should be Variable name"
  @assert condition isa Union{Symbol, AbstractString} "3rd arg should be truthy expression"

  value isa Union{AbstractString, Symbol} && (value = "\"$value\"")
  newexpr = Meta.parse("""VueJS.VueIf( ($value), true, "$condition" )""")

  quote
    $(esc(varname)) = $(esc(newexpr))
  end
end


macro velseif( varname, condition, value )
  @assert varname isa Symbol "1st arg should be Variable name"
  @assert condition isa Union{Symbol, AbstractString} "3rd arg should be truthy expression"

  value isa Union{AbstractString, Symbol} && (value = "\"$value\"")
  newexpr = Meta.parse("""VueJS.VueIf( ($value), false, "$condition" )""")

  quote
    $(esc(varname)) = $(esc(newexpr))
  end
end


macro velse( varname, value )
  @assert varname isa Symbol "1st arg should be Variable name"

  value isa Union{AbstractString, Symbol} && (value = "\"$value\"")
  newexpr = Meta.parse("""VueJS.VueIf( ($value), false, nothing )""")

  quote
    $(esc(varname)) = $(esc(newexpr))
  end
end


macro vc( varname, value )
  @assert varname isa Symbol "1st arg should be Variable name"

  newexpr = Meta.parse( """VueJS.VueCond( $value )""" )

  quote
    $(esc(varname)) = $(esc(newexpr))
  end
end
