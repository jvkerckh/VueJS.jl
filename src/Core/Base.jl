const MODULE_ROOT           = normpath(joinpath(@__FILE__,"..","..", ".."))
const DIRECTIVES            = ["v-html", "v-text", "v-for", "v-if", "v-on", "v-style", "v-show"]
const KNOWN_JS_EVENTS       = ["input", "click", "mouseover", "mouseenter", "change"]
const CONTEXT_JS_FUNCTIONS  = ["submit", "add", "remove"]
const JS_FUNCTION_ATTRS     = ["rules", "filter", "col_format", "formatter"] ## Formatter is an Echarts Tag
const KNOWN_EVT_PROPS       = ["methods", "computed", "watch"] 
const KNOWN_HOOKS = [
    "beforeCreate",
    "created",
    "beforeMount",
    "mounted",
    "beforeUpdate",
    "updated",
    "beforeDestroy",
    "destroyed",
    "activated",
    "deactivated"
]

# Structures/types acceptable for HTML conversion
const htmlTypes = Union{Nothing,String,HtmlElement,VueElement,VueStruct,VueJS.VueHolder}

const JS_VAR_CHARS       = vcat(Char.(48:57),Char.(65:90),Char(95),Char.(97:122))
const JS_FIRST_VAR_CHARS = vcat(Char.(65:90),Char(95),Char.(97:122))

# Defaults to deps.json @ package root
const BASE_LIBRARIES  = normpath(joinpath(@__DIR__,"..","..", "deps.json"))

const FRAMEWORK = "vuetify"

# Default <meta> tags for generated pages
const META = Vector{HtmlElement}([
    html("meta","", Dict("charset"=>"UTF-8")),
    html("meta","", Dict("name"=>"viewport","content" => "width=device-width, initial-scale=1")),
])

# Default <head> for generated pages
HEAD = html("head", META, Dict())

LIBRARY_RULES =
    Dict("maxchars" => (x->return "value => value.length <= $x || 'Max $x characters' "),
        "minchars"  => (x->return "value => value.length > $x  || 'Min $x characters' "),
        "required"  => (x->return "value => !!value || 'Required' "),
        "min"       => (x->return "value => value >= $x || 'Minimum  value is $x' "),
        "max"       => (x->return "value => value <= $x || 'Maximum  value is $x' "),
        "type"      => (x->return "value => typeof(value) === '$x' || 'Please provide a $x'"),
        "in"        => (x->return "value => $x.includes(value) || 'Value not in $x' ")
    )

DEPENDENCIES = []

## Dom Render Opts
mutable struct Opts
    rows::Bool
    style::Dict{String,Any}
    class::Dict{String,Any}
    css::Dict{String,Dict{String,String}}
    path::String
    vars_replace::Dict{String,String}
end

const PAGE_OPTIONS = 
    Opts(
        true,
        Dict("viewport"=>"md","v-col"=>Dict("align"=>"center","align-content"=>"center","justify"=>"center")),
        Dict(),
        Dict(),
        "root",
        Dict()
    )

struct VueElementSettings
    library::String
    doc::String
    value_attr::Union{Nothing,String}
    fn::Function    
end

function VueElementSettings(nt::NamedTuple)
    
    library=get(nt,:library,"vuetify")
    doc=get(nt,:doc,"")
    value_attr=get(nt,:value_attr,"value")
    fn=nt.fn
    
    return VueElementSettings(library,doc,value_attr,fn)
end

import Base.convert
Base.convert(::Type{VueElementSettings}, x::NamedTuple) = VueElementSettings(x)

const UPDATE_VALIDATION = Dict{String,VueElementSettings}()

"""
    meta(entry::Pair)
    meta(entry::Dict)
    meta(entries::Vector)

Transform a Dict <meta> entry into an HtmlElement

Examples:

```julia

VueJS.meta(Dict("name"=>"viewport", "content" => "width=device-width, initial-scale=.7"))
# VueJS.HtmlElement("meta", Dict{String,Any}("name" => "viewport","content" => "width=device-width, initial-scale=.7"), 2.0, "")

VueJS.meta([
        Dict("name"=>"description", "content"=>"Web page description"), 
        Dict("name"=>"author", "content"=>"VueJS")
    ])
#=
2-element Array{VueJS.HtmlElement,1}:
    Main.VueJS.HtmlElement("meta", Dict{String,Any}("name" => "description","content" => "Web page description"), 2.0, "")
    Main.VueJS.HtmlElement("meta", Dict{String,Any}("name" => "author","content" => "VueJS"), 2.0, "")
=#
``
"""
meta(entry::Pair)          = meta(Dict(entry))
meta(entry::Dict)          = html("meta", "", entry)
meta(entries::Vector)      = meta.(entries)
meta(element::HtmlElement) = element

"""
    head(pair::Pair)
    head(entries::Vector)

Transform a Dict into html tags for <head> inclusion

Examples
```julia

VueJS.head("title"=>"Page Title")
# VueJS.HtmlElement("title", Dict{String,Any}(), 2.0, "Page Title")

VueJS.head([
        "title"=>"Page Title",
        "link"=>Dict("rel"=>"stylesheet", "href"=>"styles.css")
    ])
#= 
2-element Array{VueJS.HtmlElement,1}:
    Main.VueJS.HtmlElement("title", Dict{String,Any}(), 2.0, "Page Title")
    Main.VueJS.HtmlElement("link", Dict{String,Any}("rel" => "stylesheet","href" => "styles.css"), 2.0, "")
=#
````
"""
function head(pair::Pair)
    if last(pair) isa String return html(first(pair), last(pair), Dict()) end
    if last(pair) isa Dict   return html(first(pair), "", last(pair))     end
end
head(entries::Vector)               = head.(entries)
head(element::HtmlElement)          = element

"""
    extension(path::String)

Given a `path`, if the last component of contains a dot, return the file extension without the dot.
Returns an empty string if no extension is found for `path`

Examples
```julia

VueJS.extension("/dir/libs/somefile.jl") # "jl"
VueJS.extension("/dir/libs/somefile")    # ""
```
"""
extension(path::String) = splitext(path)[end][2:end]

function library(url::String)
    return VueJS.WebDependency(name=basename(url), path=url, type=extension(url))
end
function library(url::String, type::String)
    return VueJS.WebDependency(name=basename(url), path=url, type=type)
end
function library(url::String, components::Dict)
    return VueJS.WebDependency(name=basename(url), path=url, type=extension(url), components=components)
end
library(;kwargs...) = WebDependency(kwargs...)

function libraries!(a::Vector)
    deps_arr = []
    for r in a
        if r isa String push!(deps_arr, library(r))    end
        if r isa Tuple  push!(deps_arr, library(r...)) end
    end
    global DEPENDENCIES = deps_arr
    return;
end

"""
    load_libraries!(filepath::String)

Replace or append to `global DEPENDENCIES` with file contents @ `filepath`

Examples
```julia

VueJS.load_libraries!("/public/mydeps.json")
```
"""
function load_libraries!(filepath::String; replace=true, filter_func=(x)->Base.get(x, "repo", "VueJS.jl") == "VueJS.jl")
    @assert isfile(filepath) "File $filepath not found"
    arr_deps = JSON.parse(read(filepath, String))
    webdeps  = [WebDependency(
                    get(x, "name", basename(x["url"])), 
                    x["url"], 
                    x["version"], 
                    get(x, "type", extension(basename(x["url"]))), 
                    get(x,"components",Dict()), 
                    get(x,"css",""), 
                    "", 
                    get(x, "path", "")) 
            for x in arr_deps if filter_func(x)]
    if replace
        global DEPENDENCIES = webdeps
    else
        append!(DEPENDENCIES, webdeps)
    end
end
# load default dependencies into `global DEPENDENCIES`
load_libraries!(BASE_LIBRARIES)

using Downloads
function download_web_dependency(dependency::WebDependency; dir=joinpath(MODULE_ROOT, "assets"), output::String=joinpath(dir, dependency.name))
    !ispath(dir) && mkpath(dir)
    return Downloads.download(dependency.path, output)  
end

function use_local_libs!(;deps::Vector{WebDependency}=DEPENDENCIES, base_uri="/", download=true, dir=joinpath(MODULE_ROOT, "assets"))
    if download 
        isdir(dir) || mkpath(dir)
        for d in DEPENDENCIES
            try 
                file = download_web_dependency(d, dir=dir)
                d.local_path = file
                d.path = joinpath(base_uri, split(abspath(normpath(file)), "/", keepempty=false)[2:end-1]..., basename(file))
            catch err 
                @warn err
            end
        end
    end
end

function assert_html_types(v::Vector)
    for r in v
        if r isa Vector
           assert_html_types(r)
        else
            @assert r isa htmlTypes "$r is not an acceptable HtmlType"
        end
    end
end

function trf_vue_expr(expr::String;opts=PAGE_OPTIONS)
        
    if opts.path=="" return expr  end
    
    expr=replace(expr,"\""=>"'")
    expr_arr=split(expr,"'")   
    expr_out=Vector{String}()
    expr_arr[1]=="" ? is_quoted=false : is_quoted=true
        
   ## iterate blocks of code
   for s in expr_arr
        
        is_quoted=!is_quoted
        
        if is_quoted
            push!(expr_out,"'$s'")
        else
            
            ## Total Match (e.g. submit)
            if s in CONTEXT_JS_FUNCTIONS
                s=get(opts.vars_replace,s,s)*"()"
                push!(expr_out,s)
                continue
            end

            text_seg=Vector{Char}()
            lns=length(s)
            is_var_char=false
            prev_oper=' '
            ## Iterate Chars
            for (i,chr) in enumerate(s)
               
                new_var_char=chr in JS_VAR_CHARS
                
                if (i!=1 && new_var_char!=is_var_char)
                    strf=String(text_seg)
                    if prev_oper!='.'
                        strf=get(opts.vars_replace,strf,strf)
                    end
                    push!(expr_out,strf)
                    prev_oper=text_seg[end]
                    text_seg=Vector{Char}()
                    push!(text_seg,chr)
                else
                    push!(text_seg,chr)
                end
                
                is_var_char=new_var_char
            end
                if length(text_seg)!=0
                    strf=String(text_seg)
                    if prev_oper!='.'
                        strf=get(opts.vars_replace,strf,strf)
                    end
                    push!(expr_out,strf)
                end
        end
    end
    return join(expr_out)
end


merge_class!( class::Dict{String,Any}, newclass::Dict{String,Any} ) =
    merge!( class, newclass )
merge_class!( class::Dict{String,Any}, newclass::Vector{String} ) =
    merge!( class, Dict( cl => "" for cl in newclass ) )
merge_class!( class::Dict{String,Any}, newclass::Vector{T} ) where T <: AbstractString = merge_class!( class, Vector{String}(newclass) )
merge_class!( class::Dict{String,Any}, newclass::AbstractString ) =
    merge_class!( class, filter!( cl -> !isempty(cl), split( newclass, ' ' ) ) )
