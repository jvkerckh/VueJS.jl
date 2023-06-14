module VueJS

using JSON,Dates,DataFrames,HTTP,Namtso
using SHA,Base64

export WebDependency,html,spacer
export grid,page,@el,@st,@vr,@dialog,response,submit,tabs,bar,card,libraries!,toolbar,toolbartitle
export dialog, expansion_panels, VueStruct
export LIBRARY_RULES
export get_web_dependencies!
export @style,@class,@css
export VueSFC, sfc_page, sfc_response

include("Core/HtmlElement.jl")
include("Core/VueElement.jl")
include("Core/VueHolder.jl")
include("Core/Events.jl")
include("Core/VueStruct.jl")
include("Core/Conditional.jl")
include("Core/Loops.jl")
include("Core/SFC.jl")
include("Core/Binding.jl")
include("Core/Data.jl")
include("Core/Dom.jl")
include("Core/Page.jl")
include("Core/Base.jl")
include("Core/Parsing.jl")
include("Core/Update_validation.jl")
include("Core/Style.jl")
include("Vuetify/Vuetify.jl")
include("Echarts/EchartsBase.jl")


end
