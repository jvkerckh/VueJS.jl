function is_own_attr(v::VueJS.VueElement,k::String)
    karr=split(k,'.')
    if length(karr)==2
        if karr[1]==v.id && haskey(v.attrs,karr[2])
            return true 
        else 
            return false
        end
    else
       return false 
    end
end

function update_dom(r::VueElement;opts=PAGE_OPTIONS,is_child=false)

    ## Is Child Explicit item. in child attrs
    if is_child
        ## Un Bind Things
        for (k,v) in r.binds
            if k==r.value_attr
                ka="value"
                value=get(r.attrs,ka,nothing)
            else
                value=get(r.attrs,k,nothing)
            end
            
            value==nothing ? value=v : nothing
            
            if value isa AbstractString && occursin("item.",value)
                r.attrs[":$k"]=trf_vue_expr(value,opts=opts)               
                if k==r.value_attr 
                    event=r.value_attr=="value" ? "input" : "change"
                    ev_expr=get(r.attrs,"type","")=="number" ? "$value= toNumber(\$event);" : "$value= \$event;"
                      if haskey(r.attrs,event)
                        r.attrs[event]=ev_expr*r.attrs[event]*";"
                    else
                        r.attrs[event]=ev_expr
                    end
                    delete!(r.attrs,ka)
                else     
                    delete!(r.attrs,k)
                end
            elseif value!=nothing
                r.attrs[k]=value
            else
                r.attrs[k]=""
            end
        end
        r.binds=Dict()
    end    
        
    ## cycle through attrs
    for (k,v) in r.attrs
        if k in DIRECTIVES
            r.attrs[k]=trf_vue_expr(v,opts=opts)
        elseif is_event(k) 
            value=keys_id_fix(v)
            r.attrs[k]=trf_vue_expr(value,opts=opts)
        end
    end
    
    ## cycle through binds
    for (k,v) in r.binds
        value=opts.path=="" ? v : opts.path*"."*v
        ## Expressions
        if k!=r.value_attr && !(is_own_attr(r,v))
            r.attrs[":$k"]=trf_vue_expr(v,opts=opts)
            delete!(r.attrs,k)
         
        ## Own attrs
        else
            r.attrs[":$k"]=vue_escape(value)
            delete!(r.attrs,k)
        end
    end

    ## Bind with Value Attr
    if haskey(r.binds,r.value_attr)
        v=r.binds[r.value_attr]
        value=opts.path=="" ? v : opts.path*"."*v
        event=r.value_attr=="value" ? "input" : "change"
        ev_expr=get(r.attrs,"type","")=="number" ? "$value= toNumber(\$event);" : "$value= \$event;"
        if haskey(r.attrs,event)
            r.attrs[event]=ev_expr*r.attrs[event]*";"
        else
            r.attrs[event]=ev_expr
        end
    end
    
    return r
end


dom(d;opts=PAGE_OPTIONS,prevent_render_func=false,is_child=false)=d
dom(d::Dict;opts=PAGE_OPTIONS,prevent_render_func=false,is_child=false)=JSON.json(d)
dom( r::AbstractString; opts=PAGE_OPTIONS, prevent_render_func=false, is_child=false) = String(r)
function dom(r::HtmlElement;opts=PAGE_OPTIONS,prevent_render_func=false,is_child=false)
   
    if r.value isa Vector
       r.value=map(x->dom(x,opts=opts),r.value) 
    else
        r.value=dom(r.value,opts=opts)
    end
    
    for (k,v) in r.attrs
        if k in DIRECTIVES
            r.attrs[k]=trf_vue_expr(v,opts=opts)            
        end
    end
    
    return r
end



function dom(vuel_orig::VueJS.VueElement;opts=VueJS.PAGE_OPTIONS,prevent_render_func=false,is_child=false)

    vuel=deepcopy(vuel_orig)
        
    if vuel.render_func!=nothing && prevent_render_func==false
       dom_ret=vuel.render_func(vuel,opts=opts)
    else
        vuel=VueJS.update_dom(vuel,opts=opts,is_child=is_child)

        child=nothing
        ## Value attr is nothing
        if vuel.value_attr==nothing
            if haskey(vuel.attrs,"content")
                child=vuel.attrs["content"]
                delete!(vuel.attrs,"content")
            end
            if haskey(vuel.attrs,":content")
                child="""{{$(vuel.attrs[":content"])}}"""
                delete!(vuel.attrs,":content")
            end
        end

        ## cols
        vuel.cols==nothing ? vuel.cols=1 : nothing
    
       if vuel.child!=nothing
           child=vuel.child
       else
           child=child==nothing ? "" : child
       end

       child_dom=child=="" ? "" : dom(child,opts=opts,is_child=true)
        
       dom_ret=VueJS.HtmlElement(vuel.tag, vuel.attrs, vuel.cols, child_dom)
        
    end
        
    ## Tooltip 
    tooltip=get(vuel.no_dom_attrs,"tooltip",nothing)
    if tooltip!=nothing
       dom_ret=VueJS.activator(tooltip,dom_ret,"v-tooltip") 
    end
    
    ## Menu 
    menu=get(vuel.no_dom_attrs,"menu",nothing)
    if menu!=nothing
        
       dom_ret=VueJS.activator(menu,dom_ret,"v-menu") 
       path=opts.path=="" ? "" : opts.path*"."
       if haskey(vuel.attrs,"click")
            # place @click at list-item level, not at the template level
            [x.attrs["click"] = vuel.attrs["click"] for x in dom_ret.value[1].value.value if x.tag == "v-list-item"]
            #dom_ret.value[1].value.attrs["click"]=vuel.attrs["click"]
            delete!(vuel.attrs,"click")
        end
       dom_ret.value[1].value.attrs["v-for"]="(item, index) in $path$(vuel.id).items"
       delete!(dom_ret.attrs,"items")
       delete!(dom_ret.value[1].attrs,"items")
       
    end
    
    return dom_ret
end

function activator(activated::VueJS.VueElement,dom_ret::VueJS.HtmlElement,act_type::String)
    
    dom_act=dom(activated,is_child=true)
    
    return activator(dom_act,dom_ret,act_type)
end

function activator(dom_act::VueJS.HtmlElement,dom_ret::VueJS.HtmlElement,act_type::String)
    @assert dom_act.tag==act_type "Element $dom_act cannot be activated!"
    dom_ret.attrs["v-on"]="on"
    dom_template=html("template",dom_ret,Dict("v-slot:activator"=>"{on}"))
    dom_act.cols=dom_ret.cols
    
    if dom_ret.value==nothing
       dom_act.value=dom_template
    else
        dom_act.value=[dom_act.value,dom_template]
    end

    return dom_act
end

function activator(dom_act::String,dom_ret::VueJS.HtmlElement,act_type::String)
    
    dom_ret.attrs["v-on"]="on"
    dom_template=html("template",dom_ret,Dict("v-slot:activator"=>"{on}"))
    dom_act=html(act_type,[dom_act,dom_template])
    dom_act.cols=dom_ret.cols

    return dom_act
end

function activator(items::Vector,dom_ret::VueJS.HtmlElement,act_type::String)
      @el(new_menu,"v-menu",items=items)
      dom_act=VueJS.dom(new_menu,is_child=true)
      dom_act=activator(dom_act,dom_ret,act_type)

    return dom_act
end

get_cols(v::AbstractString; rows=true ) = 0.0

function get_cols(v::Array;rows=true)
    if rows
        return sum(map(x->get_cols(x,rows=rows),v))
    else
        return maximum(map(x->get_cols(x,rows=rows),v))
    end
end

function get_cols(v::VueJS.HtmlElement;rows=true)
    
    if v.tag=="v-row"
        return get_cols(v.value,rows=true)
    elseif v.tag=="v-col"
        return get_cols(v.value,rows=false)
    else
        return v.cols
    end
end


update_cols!(h::Nothing;context_cols=12,opts=PAGE_OPTIONS)=nothing
update_cols!(h::String;context_cols=12,opts=PAGE_OPTIONS)=nothing
update_cols!(h::Array;context_cols=12,opts=PAGE_OPTIONS)=update_cols!.(h,context_cols=context_cols,opts=opts)

function update_cols!(h::HtmlElement;context_cols=12,opts=PAGE_OPTIONS)

    if h.tag=="v-row"
        # h.attrs=get(opts.style,h.tag,Dict())
        merge!( h.attrs, get(opts.style,h.tag,Dict()) )  # New
        class=get(opts.class,h.tag,Dict())
        class!=Dict() ? h.attrs["class"]=class : nothing
        update_cols!(h.value,context_cols=context_cols,opts=opts)
    elseif h.tag=="v-col"
        # h.attrs=get(opts.style,h.tag,Dict())
        merge!( h.attrs, get(opts.style,h.tag,Dict()) )  # New
        class=get(opts.class,h.tag,Dict())
        class!=Dict() ? h.attrs["class"]=class : nothing
        cols=get_cols(h.value,rows=false)
        viewport=get(opts.style,"viewport","md")
        precise_cols=cols/(context_cols/12)
        cols_dec=precise_cols%1
        h.attrs[viewport]=Int(round(precise_cols))
        style=get(opts.style,h.tag,Dict())
        if cols_dec!=0
           perc_width=Int(round(precise_cols/12*100))
           if cols_dec>0.5 
               class!=Dict() ? nothing : h.attrs["class"]="flex-shrink-1"
               h.attrs["style"]="max-width: $(perc_width)%;"
            else
               class!=Dict() ? nothing : h.attrs["class"]="flex-grow-1"
               h.attrs["style"]="max-width: $(perc_width)%;"
            end 
        end
        update_cols!(h.value,context_cols=cols,opts=opts)
    elseif h.value isa HtmlElement || h.value isa Array
      update_cols!(h.value,context_cols=context_cols,opts=opts)
    end
  
    return nothing
  end
  

function dom(r::VueStruct;opts=PAGE_OPTIONS)
        
    opts=deepcopy(opts)
    merge!(opts.style,get(r.attrs,"style",Dict{Any,Any}()))
    merge!(opts.class,get(r.attrs,"class",Dict{Any,Any}()))
    
    ## Paths
    if r.iterable
        vs_path=opts.path in ["root",""] ? r.id : opts.path*"."*r.id

        opts.path=r.id*"_item"

        ks=collect(keys(get(update_data!(r,r.data),r.id,Dict())["value"][1]))
        opts.vars_replace=Dict(k=>"$(opts.path).$k" for k in vcat(ks,CONTEXT_JS_FUNCTIONS))
    else
        opts.path=opts.path=="root" ? "" : (opts.path=="" ? r.id : opts.path*"."*r.id)
        if opts.path!=""
            opts.vars_replace=Dict(k=>"$(opts.path).$k" for k in vcat(collect(keys(r.def_data)),CONTEXT_JS_FUNCTIONS))
        end
    end
    
    ## Render
    if r.render_func!=nothing
        domvalue=r.render_func(r,opts=opts)
    else
       domvalue=dom(r.grid,opts=opts)
    end
    
    if r.iterable
        iter_cols=get_cols(domvalue,rows=true) ## Iterable VS assumes row based
        domvalue=html("v-container",domvalue,cols=iter_cols,Dict("v-for"=>"($(opts.path),index) in $(vs_path).value","fluid"=>true))
    end
    
    return domvalue
end

function dom(r::VueJS.VueHolder;opts=PAGE_OPTIONS)
    
    opts.path=="root" ? opts.path="" : nothing
    
    if r.render_func!=nothing
        domvalue=r.render_func(r,opts=opts)
        if r.cols!=nothing
            domvalue.cols=r.cols
        elseif domvalue.cols==nothing
            domvalue.cols=get_cols(domvalue)
        end
        
        return domvalue
    else
        
        domvalue=deepcopy(dom(r.elements,opts=opts))
        
        if r.cols!=nothing
            cols=r.cols
        else
            cols=get_cols(domvalue)
        end
                
        return HtmlElement(r.tag,r.attrs,cols,domvalue)
    end
end

function dom(arr::Array;opts=PAGE_OPTIONS,is_child=false)
    opts.path == "root" && (opts.path = "")
    is_child && return dom.( arr, opts=opts, is_child=is_child )
    
    arr_dom=[]
    i_rows=[]

    for (i,rorig) in enumerate(arr)
        r=deepcopy(rorig)

        ## update grid_data recursively
        append=false
        new_opts=deepcopy(opts)

        r isa VueStruct && !r.iterable && (append = true)
        r isa VueStruct && (new_opts.rows = true)
        r isa Array && (new_opts.rows = !opts.rows)

        domvalue = dom(r,opts=new_opts)

        grid_class=opts.rows ? "v-row" : "v-col"
        
        ## Row with single element (1 column)
        domvalue=(opts.rows && typeof(r) in [VueHolder,VueElement,HtmlElement#=,String=#]) ? HtmlElement("v-col",Dict(),domvalue.cols,domvalue) : domvalue

        ### New Element with row/col
        new_el=HtmlElement(grid_class,Dict(),get_cols(domvalue),domvalue)

        # New (doesn't work as intended!)
        if r isa VueIf
          if isnothing(r.condition)
            new_el.attrs["v-else"] = missing
          elseif r.firstcond
            new_el.attrs["v-if"] = deepcopy(domvalue.attrs["v-if"])
          else
            new_el.attrs["v-else-if"] = deepcopy(domvalue.attrs["v-else-if"])
          end
  
          delete!.( Ref(domvalue.attrs), ["v-if", "v-else-if", "v-else"] )
        end
  
        if ((i!=1 && i_rows[i-1]) || (opts.rows)) && append
            domvalue isa Vector ? append!(arr_dom, domvalue) : push!(arr_dom, domvalue)
        else
            push!(arr_dom,new_el)
        end

        push!(i_rows,opts.rows)
    end

    update_cols!(arr_dom,opts=opts)
    arr_dom
end
  

function dom( vf::VueFor; opts=PAGE_OPTIONS )
    opts = deepcopy(opts)
    merge!( opts.style, get( vf.attrs, "style", Dict{Any,Any}() ) )
    merge!( opts.class, get( vf.attrs, "class", Dict() ) )
  
    domvalue = vf.render_func isa Nothing ? dom( vf.value, opts=opts ) :
      vf.render_func( vf, opts=opts )
    
    html( "v-container", domvalue, Dict( "v-for" => "($(vf.itervar), index) in $(vf.listname)", "fluid" => true ), cols=vf.cols )
end
  
  
function dom( vif::VueIf; opts=PAGE_OPTIONS )
    domvalue = dom( vif.value, opts=opts )
    domvalue isa Array && (domvalue = length(domvalue) == 1 ? domvalue[1].value : html( "div", domvalue, cols=0 ))
    domvalue isa String && (domvalue = html( "span", domvalue, cols=0 ))
    
    if vif.condition isa Nothing
        domvalue.attrs["v-else"] = missing
    elseif vif.firstcond
        domvalue.attrs["v-if"] = vif.condition
    else
        domvalue.attrs["v-else-if"] = vif.condition
    end
  
    domvalue
end
  
  
function dom( vc::VueCond; opts=PAGE_OPTIONS )
    domvalue = dom.( vc.value, opts=opts )
    html( "span", domvalue, cols=maximum(getfield.( domvalue, :cols )) )
end
  