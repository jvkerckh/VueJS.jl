function max_cols(v::htmlElement)
    
    if v.tag=="v-row"
        return v.value isa Array ? sum(map(x->max_cols(x),v.value)) : max_cols(v.value)
    elseif v.tag=="v-col"
        return v.value isa Array ? maximum(map(x->max_cols(x),v.value)) : max_cols(v.value)
    else
        return v.cols
    end
    
end

function grid(arr::Array;rows=true)
    
    arr_dom=[]
    
    i_rows=[]
    for (i,rorig) in enumerate(arr)
       
        r=deepcopy(rorig)
        
        ## update grid_data recursively
        append=false
        
        ## Vue Element
            if r isa VueElement
            
            ## Bind el values
                for (k,v) in r.binds
                    value=r.path=="" ? v : r.path*"."*v
                    r.dom.attrs[":$k"]=value
                
                    ### Capture Event if tgt=src otherwise double count
                    if r.id*"."*k==v
                        ## And only if value attr! Others do not change on input! I Think!
                        if r.value_attr==k
                            if haskey(r.dom.attrs,"@input")
                                r.dom.attrs["@input"]=r.dom.attrs["@input"]*"; "*"$value= \$event;"
                            else
                                r.dom.attrs["@input"]="$value= \$event"
                            end
                        end
                    end
                    
                    ### delete atribute from dom
                    if haskey(r.dom.attrs,k)
                        delete!(r.dom.attrs,k)
                    end

                end     
            
               domvalue=r.dom

            ## Vue Component
            elseif r isa VueJS.VueComponent
                append=true
                domvalue=grid(r.grid,rows=true)
          
            ## Array Elements/Components
            elseif r isa Array                
                domvalue=grid(r,rows=(rows ? false : true))
            
            elseif r isa String                
                domvalue=htmlElement("div",Dict(),12,r)
            else

                error("$r with invalid type for Grid!")
            end
   
        grid_rows="v-row"
        grid_cols="v-col"
        grid_class=rows ? grid_rows : grid_cols
        
        ## one row only must have a single col
        domvalue=(rows && typeof(r) in [VueElement,String]) ? htmlElement(grid_cols,Dict(),domvalue.cols,domvalue) : domvalue
        
        cols=domvalue isa Array ? maximum(max_cols.(domvalue)) : max_cols(domvalue)
        
        ## New Element
        cols_attrs=rows ? Dict() : Dict(VIEWPORT=>cols)
        new_el=htmlElement(grid_class,cols_attrs,cols,domvalue)
        
        if ((i!=1 && i_rows[i-1]) || (rows)) && append
        append!(arr_dom,domvalue)
        else
        push!(arr_dom,new_el)
        end
           
    push!(i_rows,rows)
    end
    return arr_dom

end