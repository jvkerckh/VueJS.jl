function htmlstring(page_inst::Page)
    includes=[]
    for d in page_inst.dependencies
        if d.kind=="js"
            push!(includes,HtmlElement("script",Dict("src"=>d.path),""))
        elseif d.kind=="css"
            push!(includes,HtmlElement("link",Dict("rel"=>"stylesheet","type"=>"text/css","href"=>d.path)))
        end
    end

    head_dom=deepcopy(HEAD)
    append!(head_dom.value,includes)   
    
    push!(head_dom.value,HtmlElement("style","[v-cloak] {display: none}"))
        
    scripts=deepcopy(page_inst.scripts)
    push!(scripts,"const vuetify = new Vuetify()")
    components=Dict{String,String}()
    for d in page_inst.dependencies
        length(d.components)!=0 ? merge!(components,d.components) : nothing
    end
    
    push!(scripts,"""const components = $(replace(JSON.json(components),"\""=>""))""")
    
    components_dom=[]
    app_state=Dict{String,Any}()
    ## Other components
    for (k,v) in page_inst.components
        if k=="v-content"
            ## component script
            comp_script=[]
            push!(comp_script,"el: '#app'")
            push!(comp_script,"vuetify: vuetify")
            push!(comp_script,"components:components")
            push!(comp_script,"data: app_state")
            push!(comp_script, v.scripts)
            merge!(app_state,v.def_data)

            comp_script="var app = new Vue({"*join(comp_script,",")*"})"
            push!(scripts,comp_script)    
            
            push!(components_dom,HtmlElement("v-content",HtmlElement("v-container",Dict("fluid"=>true),dom(v))))
        else
            
            if v isa VueHolder
                vs=VueStruct("",[VueStruct(vue_escape(k),[v])])
            else
                vs=VueStruct(vue_escape(k),[v])
            end
            
            update_events!(vs)
            comp_el=VueJS.dom([vs])[1].value.value            
            merge!(app_state,vs.def_data)
            comp_el.attrs["app"]=true
            push!(components_dom,comp_el)
        end
    end
    
    scripts=vcat("const app_state = $(vue_json(app_state))",scripts)
        
    styles=HtmlElement("style",Dict("type"=>"text/css"),join([".$k {$v}" for (k,v) in page_inst.styles]))
    
    body_dom=HtmlElement("body",[styles,
                        HtmlElement("div",Dict("id"=>"app","v-cloak"=>true),
                                 HtmlElement("v-app",components_dom))])
    
    htmlpage=HtmlElement("html",[head_dom,body_dom])
    
    return join([htmlstring(htmlpage), """<script>$(join(scripts,"\n"))</script>"""])
end