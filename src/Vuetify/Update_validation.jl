UPDATE_VALIDATION["v-file-input"]=(
doc="Component for file upload, allows multiple files. When used, the submit function will submit all the files including contents and filenames. In server side parse the request with:<br>
    <code>
    function example(req::HTTP.Request)<br>
    VueJS.parse(req)
    </code>",
value_attr="input-value",
fn=(x)->begin
    haskey(x.attrs,"multiple") ? nothing : x.attrs["multiple"]=false
end)

UPDATE_VALIDATION["v-tooltip"]=(
doc="""Should be used as a argument in other elements. Example:<br>
    <code>
    @el(ttp,"v-tooltip",content="Tooltip Text",bottom=true,color="rgba(0, 0, 255, 0.5)")<br>
    @el(ch1,"v-chip",content="Tooltip",tooltip=ttp)
    </code>
    """,
value_attr=nothing,
fn=(x)->x)

UPDATE_VALIDATION["v-menu"]=(
doc="""Should be used as a argument in other elements, normally v-btn. Example:<br>
    <code>
    items=[Dict("title"=>"Action 1","val"=>"BATATA"),Dict("title"=>"Action 2","val"=>"https://www.amazon.com")]<br>
    @el(menu,"v-menu",items=items,dark=true)<br>
    @el(m2,"v-btn",menu=menu,value="Menu")<br>
    </code>
    """,
value_attr=nothing,
fn=(x)->begin
    haskey(x.attrs,"offset-y") ? nothing : x.attrs["offset-y"]=true
    @el(menu_list,"v-list",items=x.attrs["items"])
    x.child=menu_list
end)

UPDATE_VALIDATION["v-switch"]=(
doc="""Simple element, value attribute is input-value. Switch value on is true, off is false.<br>
    <code>
    @el(sw,"v-switch",label="Switch",value=false)<br>
    </code>
    """,
value_attr="input-value",    
fn=(x)->begin
    x.attrs["true-value"]=true
    x.attrs["false-value"]=false
    x.attrs["input-value"] = get( x.attrs, "value", false )
end)

UPDATE_VALIDATION["v-checkbox"]=(
doc="""Simple element, value attribute is input-value. CheckBox ticked value is true, non ticked is false.<br>
    <code>
    @el(sw,"v-checkbox",label="Check",value=false)<br>
    </code>
    """,
value_attr="input-value",
fn=(x)->begin
    x.attrs["true-value"]=true
    x.attrs["false-value"]=false
    x.attrs["input-value"] = get( x.attrs, "value", false )
end)

UPDATE_VALIDATION["v-chip"]=(
doc="""Simple Element, value attribute is nothing, when submitted has no value. Can be used with with events,e.g. click (like any other vuetify element)<br>
    <code>
    @el(chip,"v-chip",content="Chip",color="rgba(200,0,0,0.8)",text-color="white",click="open('https://www.google.com')")
    </code>
    """,
value_attr=nothing,
fn=(x)->x
)

UPDATE_VALIDATION["v-slider"]=(
doc="""Simple Element, value attribute is value. Important attributes are min and max for minimum and maximum values, thumb-label will show the selected value if true or always for persintent.<br>
    <code>
    @el(slid,"v-slider",value=0,min=0,max=50,thumb-label="always",thumb-color="red")
    </code>
    """,
fn=(x)->begin
    x.cols==nothing ? x.cols=3 : nothing
end)

UPDATE_VALIDATION["v-range-slider"]=(
doc="""Simple Element, value attribute is value, return is an array of low and high value. Important attributes are min and max for minimum and maximum values, thumb-label will show the selected value if true or always for persintent.<br>
    <code>
    @el(slid,"v-range-slider",value=[10,20],min=0,max=50,thumb-label="always",thumb-color="red")
    </code>
    """,
fn=(x)->begin
    x.cols==nothing ? x.cols=3 : nothing
end)

UPDATE_VALIDATION["v-date-picker"]=(
doc="""Simple Element, value attribute is value. Is invoked when v-text-field element has type date!. Can be used without v-text-field<br>
    <code>
    @el(dpt,"v-text-field",label="Date",type="date")<br>
    @el(dp,"v-date-picker",color="red") # utilization without text field
    </code>
    """,    
fn=(x)->begin

    x.cols==nothing ? x.cols=3 : nothing
end)

UPDATE_VALIDATION["v-color-picker"]=(
doc="""Simple Element, allows you to select a color using a variety of input methods. Is invoked when v-text-field element has type color!. Can be used without v-text-field<br>
    <code>
    @el(color_picker_in_txt_field, "v-text-field", label="Color", type="color", value="")<br>
    @el(color_picker, "v-color-picker") # utilization without text field
    </code>
    """,    
fn=(x)->begin

    x.cols==nothing ? x.cols=3 : nothing
end)



UPDATE_VALIDATION["v-text-field"]=(
doc="""Simple Element, value attribute is value. If type is date invokes a date picker, if type is color invokes a color picker and finally, if type is number when submited the value will be a valid number in JSON.<br>
    <code>
    @el(tf1, "v-text-field", label="Text Field")                              <br>
    @el(tf2, "v-text-field", label="Number Field", type="number")             <br>
    @el(tf3, "v-text-field", label="Date Field"  , type="date")               <br>
    @el(tf4, "v-text-field", label="Date Field"  , type="date",  date-attrs = Dict("type" => "month")) <br>
    @el(tf5, "v-text-field", label="Color Field" , type="color", value="")              <br>
    @el(tf6, "v-text-field", label="Color Field" , type="color", value="", color-attrs = Dict("show-swatches" => true))  <br>
    </code>
""",
fn=(x)->begin
    
    x.cols==nothing ? x.cols=2 : nothing
    
   # -- Render "v-text-field" with date-picker or color-picker.
    if get(x.attrs,"type","") == "date" || get(x.attrs,"type","") == "color"
            
        render_type = x.attrs["type"]
        type_attrs = Dict{String, Any}(get(x.attrs, "$(render_type)-attrs", Dict()))
        type_id    = render_type == "date" ? "v-date-picker" : "v-color-picker"
                        
        x.render_func=(y;opts=PAGE_OPTIONS)->begin
            path=opts.path == "" ? "" : opts.path*"."
            menu_var = "$path$(y.id).menu"
            y.binds["menu"]  = menu_var
            y.attrs["v-on"]  = "on"
            type_attrs["v-model"] = "$path$(y.id).value"
            
            # -- Cleanup of attrs not relevant to "v-text-field" element
            delete!(y.attrs,"type")
            delete!(y.attrs,"$(render_type)-attrs")
            delete!(y.binds,"$(render_type)-attrs")
            dom_txt    = VueJS.dom(y,prevent_render_func=true,opts=opts)
            domcontent = [ 
                    html("template",dom_txt,Dict("v-slot:activator"=>"{ on }")),
                    html(type_id,"", type_attrs) 
            ]
                
            return html("v-menu",domcontent,Dict("v-model"=>menu_var,"nudge-right"=>0,"nudge-bottom"=>50,"transition"=>"scale-transition","min-width"=>"290px"),cols=x.cols)    
        end
    end
end)


UPDATE_VALIDATION["v-btn"]=(
doc="""Simple Element, value attribute is nothing, when submitted has no value. Can be used with with events,e.g. click (like any other vuetify element)<br>
    <code>
    @el(b,"v-btn",content="Button",click="submit('login')",small=true,outlined=true,color="indigo")
    </code>
    """,
value_attr=nothing,
fn=(x)->begin

    ## attr alias of content
    haskey(x.attrs,"value") ? (x.attrs["content"]=x.attrs["value"];delete!(x.attrs,"value")) : nothing
end)

UPDATE_VALIDATION["v-spacer"]=(
doc="""Holder Element, helper function is the correct method to use. Special attributes are rows and cols for number of rows and cols of space.<br>
    <code>
    spacer() # One col of space<br>
    spacer(rows=2,cols=3) # 2 rows and 3 cols of space
    </code>
    """,
value_attr=nothing,
fn=(x)->x)

UPDATE_VALIDATION["v-select"]=(
doc="""Simple Element, value attribute is items. Items are the options available to select. Value is the selected item, allows for multiple.<br>
    <code>
    @el(sel,"v-select",items=["A","B","C"],multiple=true)
    </code>
    """,
fn=(x)->begin

    @assert haskey(x.attrs,"items") "Vuetify Select element with no arg items!"
    @assert typeof(x.attrs["items"])<:Array "Vuetify Select element with non Array arg items!"

    x.cols==nothing ? x.cols=2 : nothing
    
    if !haskey(x.attrs,"value")
        x.attrs["value"] = get(x.attrs, "multiple", false) != false ? [] : nothing
    end
end)

UPDATE_VALIDATION["v-autocomplete"]=(
doc="""Simple Element, value attribute is items. Items are the options available to select. Value is the selected item, allows for multiple.<br>
    <code>
    @el(sel,"v-autocomplete",items=["A","B","C"],multiple=true)
    </code>
    """,
fn=(x)->begin

    @assert haskey(x.attrs,"items") "Vuetify autocomplete element with no arg items!"
    @assert typeof(x.attrs["items"])<:Array "Vuetify autocomplete element with non Array arg items!"

    x.cols==nothing ? x.cols=2 : nothing
    
    if !haskey(x.attrs,"value")
        x.attrs["value"] = get(x.attrs, "multiple", false) != false ? [] : nothing
    end
end)

UPDATE_VALIDATION["v-radio-group"]=(
doc="",
value_attr="input-value",
fn=(x)->begin
    
    x.cols==nothing ? x.cols=1 : nothing
   
    content=get(x.attrs,"content",[])
    haskey(x.attrs,"content") ? delete!(x.attrs,"content") : nothing

    x.child=content

end)

UPDATE_VALIDATION["v-radio"]=(
doc="",
value_attr="input-value",
fn=(x)->begin
    x.cols==nothing ? x.cols=1 : nothing
end)

UPDATE_VALIDATION["v-list"]=(
doc="",
value_attr="items",
fn=(x)->begin

    @assert haskey(x.attrs,"items") "Vuetify List element with no arg items!"
    @assert typeof(x.attrs["items"])<:Array "Vuetify List element with non Array arg items!"

    if haskey(x.attrs,"item") || haskey(x.attrs,"content")
        
    
        if haskey(x.attrs,"item")
            x.child=x.attrs["item"]
            delete!(x.attrs,"item")
        else
            x.child=x.attrs["content"]
            delete!(x.attrs,"content")
        end
        
        x.render_func=(y;opts=PAGE_OPTIONS)->begin
            path=opts.path=="" ? "" : opts.path*"."
            dom_list=VueJS.dom(y,prevent_render_func=true,opts=opts)
            
            opts_item=deepcopy(opts)
            opts_item.rows=false
            
            dom_item=VueJS.dom(y.child,opts=opts_item,is_child=true)
                        
            dom_item=html("v-list-item",dom_item)
            dom_item.attrs["v-for"]="(item, index) in $path$(x.id).value"
            dom_item.attrs[":key"]="index"
            
            dom_list.value=dom_item
            dom_list
        end
    else
        items=x.attrs["items"]
            
        temp = html("template", [], Dict("v-for" => "(item, index) in $(x.id).value"))
        push!(temp.value, html("v-divider", [], Dict("v-if" => "item.divider", ":key" => "index", "class" => "ma-5")))
    
        child = html("v-list-item",[],Dict(":class" => "item.class", "dense" => true, "v-else" => true))
        
        #child.attrs["v-for"]="(item, index) in $(x.id).value"
        #child.attrs[":key"]="index"
                        
        sum(map(x->haskey(x,"avatar"),items))>0 ? push!(child.value,html("v-list-item-avatar",html("v-img","",Dict(":src"=>"item.avatar")))) : ""
        sum(map(x->haskey(x,"icon"),items))>0 ? push!(child.value,html("v-list-item-icon",html("v-icon","",Dict("v-text"=>"item.icon")))) : ""
        if sum(map(x->haskey(x,"title"),items))>0 
            contents=[]
            push!(contents,html("v-list-item-title","",Dict("v-text"=>"item.title")))
            sum(map(x->haskey(x,"subtitle"),items))>0 ? push!(contents,html("v-list-item-subtitle","",Dict("v-text"=>"item.subtitle"))) : ""
            push!(child.value,html("v-list-item-content",contents))
        end
        
        has_href=sum(map(x->haskey(x,"href"),items))>0 
        has_click=sum(map(x->haskey(x,"click"),items))>0 
        
        @assert !(has_href && haskey(child.attrs,"click")) "You must choose between href and click!"
        
        if has_href
            child.attrs["link"]=true
            child.attrs["click"]="open(item.href)"
        end
            
        push!(temp.value, child)
        x.child=temp            
    end
end)

UPDATE_VALIDATION["v-tabs"]=(
    doc="""Holder Element, helper function is the correct method to use. Accepts array of pairs key is Tab Name value is the content<br>
        <code>
        tabs(["Tab1"=>[el1,el2,el3],"Tab2"=>[el4,[el5,el6]]])
        </code>
    """,
    fn=(x)->begin
        @assert haskey(x.attrs,"names") "Vuetify tab with no names, please define names array!"
        @assert x.attrs["names"] isa Array "Vuetify tab names should be an array"
        @assert length(x.attrs["names"])==length(x.elements) "Vuetify Tabs elements should have the same number of names!"
    
        x.render_func=(y;opts=PAGE_OPTIONS)->begin
            content=[]

            for (i,r) in enumerate(y.elements)
                push!(content,HtmlElement("v-tab",Dict(),nothing,y.attrs["names"][i]))
                value=r isa Array ? dom(r,opts=opts) : dom([r],opts=opts)
                push!(content,HtmlElement("v-tab-item",Dict(),12,value))
            end

            tmpattrs = deepcopy(y.attrs)
            delete!( tmpattrs, "names" )
            HtmlElement("v-tabs",tmpattrs,12,content)
        end
    end
)

UPDATE_VALIDATION["v-navigation-drawer"]=(
doc="",
value_attr=nothing,
fn=(x)->begin

    @assert haskey(x.attrs,"items") "Vuetify navigation with no items, please define items array!"
    @assert x.attrs["items"] isa Array "Vuetify navigation items should be an array"

    item_names=collect(keys(x.attrs["items"][1]))
    x.tag="v-list"
            
    VueJS.update_validate!(x)

    x.render_func=(y;opts=PAGE_OPTIONS)->begin

        dom_nav=VueJS.dom(y,prevent_render_func=true,opts=PAGE_OPTIONS)

        nav_attrs=Dict()

        for (k,v) in Dict("clipped"=>true,"width"=>200, "expand-on-hover"=>true, "permanent"=>true, "right"=>false)
            haskey(y.attrs,k) ? nav_attrs[k]=y.attrs[k] : nav_attrs[k]=v
        end

        html("v-navigation-drawer",dom_nav,nav_attrs,cols=12)
    end
end)


UPDATE_VALIDATION["v-card"]=(
doc="", 
fn=(x)->begin

    @assert haskey(x.attrs,"names") "Vuetify card with no names, please define names array!"
    @assert x.attrs["names"] isa Array "Vuetify card names should be an array"
    @assert length(x.attrs["names"])==length(x.elements) "Vuetify card elements should have the same number of names!"

    x.render_func=(y;opts=PAGE_OPTIONS)->begin
       content=[]
        cols=1
        for (i,r) in enumerate(y.elements)
           dom_el=VueJS.dom(r,opts=opts)
           cols_el=VueJS.get_cols(dom_el,rows=false)
           cols>cols_el ? nothing : cols=cols_el
           push!(content,VueJS.HtmlElement(y.attrs["names"][i],Dict(),nothing,dom_el))
       end
        
      VueJS.HtmlElement("v-card",y.attrs,cols,content)
    end
end)

UPDATE_VALIDATION["v-alert"]=(
doc="",
value_attr=nothing,
fn=(x)->begin
    
    x.cols==nothing ? x.cols=12 : nothing
    
    ## Validations
    haskey(x.attrs,"value") ? (@assert x.attrs["value"] isa Bool "Value Attr of Alert Should be Bool") : nothing
    
    ## 3 Basic Defaults
    haskey(x.attrs,"content") ? nothing : x.attrs["content"]=""
    haskey(x.attrs,"type") ? nothing : x.attrs["type"]="success"
    haskey(x.attrs,"value") ? nothing : x.attrs["value"]=false
    
    ## 3 Basic Bindings
    x.binds["content"]=x.id*".content"
    x.binds["type"]=x.id*".type"
    x.binds["value"]=x.id*".value"
    
    x.binds["v-html"]=x.id*".content"
    
    dismissible = get(x.attrs, "dismissible", false)
    timeout = get(x.attrs, "timeout", 4000)
    delay = get(x.attrs, "delay", 0)

    timeout_func="function(val,old){val ? setTimeout(()=>{this.$(x.id).value = false}, $timeout) : ''}"
    haskey(x.events,"watch") ? x.events["watch"]["$(x.id).value"]=timeout_func : x.events["watch"]=Dict("$(x.id).value"=>timeout_func)

end)

UPDATE_VALIDATION["v-textarea"]=(
doc="""Simple Element, value attribute is value. Text Box bigger than v-text-field<br>
    <code>
    @el(tf,"v-textarea",label="Text Field",rows=10)<br>
    </code>
    """, 
fn=(x)->begin
    
    x.cols==nothing ? x.cols=3 : nothing
   
end)

UPDATE_VALIDATION["v-combobox"]=(
doc="""Simple Element. Items are the options available to select. Value is the selected items (custom or predefined), allows for multiple.<br>
    <code>
    @el(sel,"v-combobox",items=["A","B","C"],multiple=true)
    </code>
    """,
fn=(x)->begin
    x.cols==nothing ? x.cols=2 : nothing
    
    if !haskey(x.attrs,"value")
        x.attrs["value"] = get(x.attrs, "multiple", false) != false ? [] : nothing
    end
end)

UPDATE_VALIDATION["v-toolbar"]=(
doc="",
value_attr=nothing,
fn=(x)->begin
    x.render_func=(toolbar; opts=PAGE_OPTIONS)->begin
        opts.rows = true
        tcols = toolbar.cols isa Nothing ? 12 : toolbar.cols 
        child_dom = VueJS.dom([toolbar.elements], opts=opts)
        toolbar.attrs["style"] = join(["$k:$v;" for (k,v) in get(toolbar.attrs, "style", Dict())], " ")
        return VueJS.HtmlElement(toolbar.tag, toolbar.attrs, tcols, VueJS.HtmlElement("v-container", Dict("class"=>"container--fluid"), 12, child_dom))
    end
end)

UPDATE_VALIDATION["v-treeview"]=(
doc="""The <code> v-treeview </code> component is useful for displaying large amounts of nested data by using a tree format.
Its behaviour is manipulated by using the various props from the vuetify library. Input data must be in tree format (see example <a href="https://github.com/vuetifyjs/vuetify/blob/master/packages/docs/src/examples/v-treeview/usage.vue">here</a> - items)

Default v-treeview; By default it is hoverable, dense, aligns to the left and occupies 6 columns
<code> @el(tree, "v-treeview", items=tree_data)  </code>

The next examples define the behaviour of a v-treeview using the prepend-icon attribute to define an prepend-icon slot. (Ex: File explorer)
EX-1: 
Default prepend. Expects "icon" field to specify icon information, else defaults to folder.
<code> @el(tree, "v-treeview", items=tree_data,  prepend-icon = true)  </code>

EX-2: 
Custom default icon. Expects "icon" field to specify icon information, else is equal to the custom default icon "mdi-alarm-note".
<code> @el(tree, "v-treeview", items=tree_data,  prepend-icon = Dict("default-icon" => "mdi-alarm-note"))  </code>

EX-3: 
Custom icon field. Expects custom icon field "file" to specify icon information, else defaults to folder.
<code> @el(tree, "v-treeview", items=tree_data,  prepend-icon = Dict("custom-icon-field" => "file"))  </code>

EX-4: 
Custom prepend. Expects custom icon field "file" to specify icon information, else defaults to custom default icon "mdi-upload".
<code> @el(tree, "v-treeview", items=tree_data,  prepend-icon = Dict("default-icon" => "mdi-upload", "custom-icon-field" => "file"))  </code>
""",
fn=(x)->begin
    
    # Default attributes
    x.cols==nothing ? x.cols=6 : nothing
    haskey(x.attrs, "selection-type") ? nothing : x.attrs["selection-type"] = "independent"
    haskey(x.attrs, "align") ? nothing : x.attrs["align"] = "left"
    for k in ["hoverable", "dense"]
        haskey(x.attrs, k) ? nothing : x.attrs[k] = true
    end

    # Prepend icon to each item based on "prepend-icon" attribute.
    if haskey(x.attrs, "prepend-icon") && (isa(x.attrs["prepend-icon"], Bool) || isa(x.attrs["prepend-icon"], Dict))
        # Default prepend-behaviour
        # looks for 'icon' in data for the icon specification and defaults to opened/closed folders when there isn't information.
        default_icon      = "{{ open ? 'mdi-folder-open' : 'mdi-folder' }}"
        custom_icon_field = "icon"
        
        # Customizable prepend-behaviour
        if isa(x.attrs["prepend-icon"], Dict) 
            # Change default icon  
            if haskey(x.attrs["prepend-icon"], "default-icon")
                default_icon = x.attrs["prepend-icon"]["default-icon"]
            end
            # Change default icon field
            if haskey(x.attrs["prepend-icon"], "custom-icon-field")
                custom_icon_field = x.attrs["prepend-icon"]["custom-icon-field"]
            end
        end
            
        slot = "<v-icon v-if='!item.$custom_icon_field'>
                    $default_icon
                 </v-icon>
                 <v-icon v-else>
                    {{ item.$custom_icon_field }}
                </v-icon>"
        
        x.slots["prepend=\"{ item, open, active }\""] = slot
    end
            
end)

                                        
UPDATE_VALIDATION["v-progress-linear"]=(
doc="""The <code> v-progress-linear </code> component is used to convey data visually to users. It's a practical way to show users that a loading or importing process is being executed at the moment.(see examples <a href="https://vuetifyjs.com/en/components/progress-linear/">here</a>)
Default v-progress-linear; By default it has width corresponding to the size of its container, is indeterminate and is hidden (inactive).
<code> @el(loading, "v-progress-linear")  </code>
""",
fn=(x)->begin
        x.cols == nothing ? x.cols = 12 : nothing
        
        ## Basic Defaults
        haskey(x.attrs, "indeterminate") ? nothing  : x.attrs["indeterminate"] = true
        haskey(x.attrs, "active")   ? nothing : x.attrs["active"]  = false
        haskey(x.attrs, "color")   ? nothing  : x.attrs["color"]   = "secondary"
        haskey(x.attrs, "style")   ? nothing  : x.attrs["style"]   = Dict("margin" => "-12px", "width" => "auto")
end)


UPDATE_VALIDATION["v-snackbar"] = (
    doc = """The v-snackbar component is used to display a quick message to a user.
            <code>
            ### Snackbars
            @el(snackbar, "v-snackbar", content = "This is a snackbar", timeout = 3000)
            </code>
            Timeout, color and content properties are all binded to the elements data *id*.timeout, *id*.color, *id*.content, so they can be dynamically changed during page interaction.
          """,
    value_attr = nothing,
    fn = (x) -> begin
        x.cols == nothing ? x.cols = 6 : nothing
        
        ## 3 Basic Defaults
        haskey(x.attrs, "content") ? nothing  : x.attrs["content"] = ""
        haskey(x.attrs, "value")   ? nothing  : x.attrs["value"] = false
        haskey(x.attrs, "color")   ? nothing  : x.attrs["color"]   = "success"
        haskey(x.attrs, "timeout") ? nothing  : x.attrs["timeout"] = 4000
        haskey(x.attrs, "style")   ? nothing  : x.attrs["style"]   = ""
        
        ## Render function
        x.render_func = (y; opts = PAGE_OPTIONS) -> begin
            path = opts.path == "" ? "" : opts.path * "."
            slot = Dict()
            slot["action=\"{ attrs }\""] = html("v-btn", "<v-icon fab>mdi-close</v-icon>", Dict("icon" => true, "@click" => "$path$(y.id).value = false"))                        
            slot = [html("template", v, Dict("v-slot:$k" => true)) for (k, v) in slot]
            
            y.binds["timeout"] = y.id * ".timeout"
            y.binds["color"]   = y.id * ".color"
            y.binds["content"] = y.id * ".content"
            y.binds["v-html"]  = y.id * ".content"
            domvalue = VueJS.dom(y, prevent_render_func = true, opts = opts)
            
            content = []            
            push!(content, "{{ snackbar.content }}")
            push!(content, slot[1])
            
            delete!(domvalue.attrs, ":value")
            domvalue.value = content
            domvalue["v-model"] = "$path$(y.id).value"
            
            return domvalue
        end
    end
)

VueJS.UPDATE_VALIDATION["v-expansion-panel"]=(
   doc = """
            The v-expansion-panel component is useful for reducing vertical space with large amounts of information.
            All v-expansion-panels must be inside a <v-expansion-panels> tag. Here is an example of how to use it:

            @el(ex_panel_1, "v-expansion-panel", header = "Test",         content = "drive")
            @el(ex_panel_2, "v-expansion-panel", header = "Another test", content = "drive")
            expansion_panels([ex_panel_1, ex_panel_2], cols = 7)
    """,
   fn = (x) -> begin
        
        x.cols == nothing ? x.cols = 4 : nothing
        
        x.render_func = (x; opts = PAGE_OPTIONS) -> begin
            children_elements = []

            # Parse header and content data
            header  = get(x.attrs, "header", Dict())
            content = get(x.attrs, "content", Dict())
            # Assert: They must be specified
            @assert !isempty(header)  "<v-expansion-panel>[$(x.id)]: Please specify text for the header section  (use kwarg 'header')"
            @assert !isempty(content) "<v-expansion-panel>[$(x.id)]: Please specify text for the content section (use kwarg 'content')"
            
            # Parse header and content style
            header_style  = Dict("style" => get(x.attrs, "header-style", Dict()))
            content_style = Dict("style" => get(x.attrs, "content-style", Dict("align" => "left")))
            
            # Clean-up root element attributes
            root_tag_attr = copy(x.attrs)
            for attr in ["header", "content", "header-style", "content-style"]
                delete!(root_tag_attr, attr)
            end
            
            push!(children_elements, html("v-expansion-panel-header",  header, header_style, cols = x.cols))
            push!(children_elements, html("v-expansion-panel-content", VueJS.dom(content), content_style, cols = x.cols))
            return html("v-expansion-panel", children_elements, root_tag_attr, cols = x.cols)
        end
    end
)
