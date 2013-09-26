abstract GtkLayouts <: GtkWidget

#GtkAlignment — A widget which controls the alignment and size of its child
#GtkAspectFrame — A frame that constrains its child to a particular aspect ratio
#GtkBox — A container box
#GtkButtonBox — A container for arranging buttons
#GtkFixed — A container which allows you to position widgets at fixed coordinates
#GtkPaned — A widget with two adjustable panes
#GtkLayout — Infinite scrollable area containing child widgets at (x,y) locations
#GtkNotebook — A tabbed notebook container
#GtkExpander — A container which can hide its child

# Introduced in Gtk3
#GtkGrid — Pack widgets in a rows and columns
#GtkRevealer — Hide and show with animation
#GtkListBox — A list container
#GtkStack — A stacking container
#GtkStackSwitcher — A controller for GtkStack
#GtkHeaderBar — A box with a centered child
#GtkOverlay — A container which overlays widgets on top of each other
#GtkExpander — A container which can hide its child
#GtkOrientable — An interface for flippable widgets

if gtk_version == 3
### GtkGrid was introduced in Gtk3 (replaces GtkTable)
type GtkGrid <: GtkLayouts
    handle::Ptr{GtkWidget}
    function GtkGrid()
        gc_ref(new(ccall((:gtk_grid_new, libgtk), Ptr{GtkWidget}, ())))
    end
end

function getindex(grid::GtkGrid, i::Integer, j::Integer)
    x = ccall((:gtk_grid_get_child_at, libgtk), Ptr{GtkWidget}, (Ptr{GtkWidget}, Cint, Cint), grid, i, j)
    x == C_NULL && error("tried to get non-existent child at [$i $j]")
    return convert(GtkWidget, x)
end

setindex!{T<:Integer,R<:Integer}(grid::GtkGrid, child, i::Union(T,Range1{T}), j::Union(R,Range1{R})) = ccall((:gtk_grid_attach, libgtk), Void,
    (Ptr{GtkWidget}, Ptr{GtkWidget}, Cint, Cint, Cint, Cint), grid, child, first(i)-1, first(j)-1, length(i), length(j))

function insert!(grid::GtkGrid, i::Integer, side::Symbol)
    if side == :left
        ccall((:gtk_grid_insert_column,libgtk), Void, (Ptr{GtkWidget}, Cint), grid, i-1)
    elseif side == :right
        ccall((:gtk_grid_insert_column,libgtk), Void, (Ptr{GtkWidget}, Cint), grid, i)
    elseif side == :top
        ccall((:gtk_grid_insert_row,libgtk), Void, (Ptr{GtkWidget}, Cint), grid, i-1)
    elseif side == :bottom
        ccall((:gtk_grid_insert_row,libgtk), Void, (Ptr{GtkWidget}, Cint), grid, i)
    else
        error(string("invalid GtkPositionType ",s))
    end
end

function insert!(grid::GtkGrid, i, side::Symbol)
    ccall((:gtk_grid_insert_next_to,libgtk), Void, (Ptr{GtkWidget}, Cint), grid, i-1)
end
else
GtkGrid(x...) = error("GtkGrid is not available until Gtk3.0")
end

### GtkTable was deprecated in Gtk3 (replaced by GtkGrid)
type GtkTable <: GtkLayouts
    handle::Ptr{GtkWidget}
    x::Cuint
    y::Cuint
    function GtkTable(x, y, homogeneous=false)
        gc_ref(new(ccall((:gtk_table_new, libgtk), Ptr{GtkWidget}, (Cint, Cint, Cint), x, y, homogeneous),x,y))
    end
end
setindex!{T<:Integer,R<:Integer}(grid::GtkTable, child, i::Union(T,Range1{T}), j::Union(R,Range1{R})) =
    ccall((:gtk_table_attach_defaults, libgtk), Void,
        (Ptr{GtkWidget}, Ptr{GtkWidget}, Cint, Cint, Cint, Cint), grid, child, first(i)-1, last(i), first(j)-1, last(j))

### GtkAlignment was deprecated in Gtk3 (replaced by properties "halign", "valign", and "margin")
type GtkAlignment <: GtkLayouts
    handle::Ptr{GtkWidget}
    function GtkAlignment(xalign, yalign, xscale, yscale) # % of available space, 0<=a<=1
        gc_ref(new(ccall((:gtk_alignment_new, libgtk), Ptr{GtkWidget},
            (Cfloat, Cfloat, Cfloat, Cfloat), xalign, yalign, xscale, yscale)))
    end
end

### GtkFrame — A bin with a decorative frame and optional label
type GtkFrame <: GtkWindows
    handle::Ptr{GtkWidget}
    function GtkFrame(label::String)
        gc_ref(new(ccall((:gtk_frame_new, libgtk), Ptr{GtkWidget},
            (Ptr{Uint8},), bytestring(label))))
    end
    function GtkFrame()
        gc_ref(new(ccall((:gtk_frame_new, libgtk), Ptr{GtkWidget},
            (Ptr{Uint8},), C_NULL)))
    end
end

### GtkAspectFrame
type GtkAspectFrame <: GtkLayouts
    handle::Ptr{GtkWidget}
    function GtkAspectFrame(xalign, yalign, ratio) # % of available space, 0<=a<=1
        gc_ref(new(ccall((:gtk_aspect_frame_new, libgtk), Ptr{GtkWidget},
            (Cfloat, Cfloat, Cfloat, Cint), xalign, yalign, ratio, false)))
    end
    function GtkAspectFrame(xalign, yalign) # % of available space, 0<=a<=1. Uses the aspect ratio of the child
        gc_ref(new(ccall((:gtk_aspect_frame_new, libgtk), Ptr{GtkWidget},
            (Cfloat, Cfloat, Cfloat, Cint), xalign, yalign, 1., true)))
    end
end

### GtkBox
type GtkBox <: GtkLayouts
    handle::Ptr{GtkWidget}
    if gtk_version == 3
        function GtkBox(vertical::Bool, spacing=0)
            gc_ref(new(ccall((:gtk_box_new, libgtk), Ptr{GtkWidget},
                (Cint, Cint), vertical, spacing)))
        end
    else
        function GtkBox(vertical::Bool, spacing=0)
            gc_ref(new(
                if vertical
                    ccall((:gtk_vbox_new, libgtk), Ptr{GtkWidget},
                        (Cint, Cint), false, spacing)
                else
                    ccall((:gtk_hbox_new, libgtk), Ptr{GtkWidget},
                        (Cint, Cint), false, spacing)
                end
                ))
        end
    end
end

### GtkButtonBox
type GtkButtonBox <: GtkLayouts
    handle::Ptr{GtkWidget}
    if gtk_version == 3
        function GtkButtonBox(vertical::Bool)
            gc_ref(new(ccall((:gtk_button_box_new, libgtk), Ptr{GtkWidget},
                (Cint,), vertical)))
        end
    else
        function GtkButtonBox(vertical::Bool)
            gc_ref(new(
                if vertical
                    ccall((:gtk_vbutton_box_new, libgtk), Ptr{GtkWidget},())
                else
                    ccall((:gtk_hbutton_box_new, libgtk), Ptr{GtkWidget},())
                end
                ))
        end
    end
end

### GtkFixed
# this is a bad option, so I'm leaving it out

### GtkPaned
type GtkPaned <: GtkLayouts
    handle::Ptr{GtkWidget}
    if gtk_version == 3
        function GtkPaned(vertical::Bool)
            gc_ref(new(ccall((:gtk_paned_new, libgtk), Ptr{GtkWidget},
                (Cint, Cint), vertical, spacing)))
        end
    else
        function GtkPaned(vertical::Bool)
            gc_ref(new(
                if vertical
                    ccall((:gtk_vpaned_new, libgtk), Ptr{GtkWidget},())
                else
                    ccall((:gtk_hpaned_new, libgtk), Ptr{GtkWidget},())
                end
                ))
        end
    end
end

function getindex(pane::GtkPaned, i::Integer)
    if i == 1
        x = ccall((:gtk_paned_get_child1, libgtk), Ptr{GtkWidget}, (Ptr{GtkWidget},), pane)
    elseif i == 2
        x = ccall((:gtk_paned_get_child2, libgtk), Ptr{GtkWidget}, (Ptr{GtkWidget},), pane)
    else
        error("tried to get pane $i of GtkPane")
    end
    x == C_NULL && error("tried to get non-existent child at $i of GtkPane")
    return convert(GtkWidget, x)
end

function setindex(grid::GtkPaned, child, i::Integer)
    if i == 1
        ccall((:gtk_paned_add1, libgtk), Void, (Ptr{GtkWidget},Ptr{GtkWidget}), pane, child)
    elseif i == 2
        ccall((:gtk_paned_add2, libgtk), Void, (Ptr{GtkWidget},Ptr{GtkWidget}), pane, child)
    else
        error("tried to set pane $i of GtkPane")
    end
end

function setindex(grid::GtkPaned, child, i::Integer, resize::Bool, shrink::Bool=true)
    if i == 1
        ccall((:gtk_paned_pack1, libgtk), Void, (Ptr{GtkWidget},Ptr{GtkWidget},Cint,Cint), pane, child, resize, shrink)
    elseif i == 2
        ccall((:gtk_paned_pack2, libgtk), Void, (Ptr{GtkWidget},Ptr{GtkWidget},Cint,Cint), pane, child, resize, shrink)
    else
        error("tried to set pane $i of GtkPane")
    end
end

### GtkLayout
type GtkLayout <: GtkLayouts
    handle::Ptr{GtkWidget}
    function GtkLayout(width, height)
        layout = ccall((:gtk_layout_new, libgtk), Ptr{GtkWidget},
            (Ptr{Void},Ptr{Void}), C_NULL, C_NULL)
        ccall((:gtk_layout_set_size,libgtk),Void,(Ptr{GtkWidget},Cuint,Cuint),layout,width,height)
        gc_ref(new(layout))
    end
end
setindex!(layout::GtkLayout, child, i::Real, j::Real) = ccall((:gtk_layout_put,libgtk),Void,
    (Ptr{GtkWidget},Ptr{GtkWidget},Cint,Cint), layout, child, i, j)
function size(layout::GtkLayout)
    sz = Array(Cuint,2)
    ccall((:gtk_layout_get_size,libgtk),Void,
        (Ptr{GtkWidget},Ptr{Cuint},Ptr{Cuint}),sz,pointer(sz,2))
    sz
end
width(layout::GtkLayout) = size(layout)[1]
height(layout::GtkLayout) = size(layout)[2]

### GtkExpander
type GtkExpander <: GtkLayouts
    handle::Ptr{GtkWidget}
    function GtkExpander(title)
        gc_ref(new(ccall((:gtk_expander_new, libgtk), Ptr{GtkWidget},
            (Ptr{Uint8},), bytestring(title))))
    end
end

### GtkNotebook
type GtkNotebook <: GtkLayouts
    handle::Ptr{GtkWidget}
    function GtkNotebook()
        gc_ref(new(ccall((:gtk_notebook_new, libgtk), Ptr{GtkWidget},())))
    end
end
function insert!(w::GtkNotebook, position::Integer, x::Union(GtkWidget,String), label::String)
    ccall((:gtk_notebook_insert_page,libgtk), Cint,
        (Ptr{GtkWidget}, Ptr{GtkWidget}, Ptr{GtkWidget}),
        w, x, label, position-1)+1
    w
end
function unshift!(w::GtkNotebook, x::Union(GtkWidget,String), label::String)
    ccall((:gtk_notebook_prepend_page,libgtk), Cint,
        (Ptr{GtkWidget}, Ptr{GtkWidget}, Ptr{GtkWidget}),
        w, x, label)+1
    w
end
function push!(w::GtkNotebook, x::Union(GtkWidget,String), label::String)
    ccall((:gtk_notebook_append_page,libgtk), Cint,
        (Ptr{GtkWidget}, Ptr{GtkWidget}, Ptr{GtkWidget}),
        w, x, label)+1
    w
end
function splice!(w::GtkNotebook, i::Integer)
    ccall((:gtk_notebook_remove_page,libgtk), Cint,
        (Ptr{GtkWidget}, Cint), w, i-1)
    w
end


### GtkOverlay
if gtk_version == 3
type GtkOverlay <: GtkLayouts
    handle::Ptr{GtkWidget}
    function GtkOverlay()
        gc_ref(new(ccall((:gtk_overlay_new, libgtk), Ptr{GtkWidget},
            (Ptr{Uint8},), bytestring(title))))
    end
end
function push!(w::GtkNotebook, x::GtkWidget)
    ccall((:gtk_overlay_add_overlay,libgtk), Cint,
        (Ptr{GtkWidget}, Ptr{GtkWidget}), w, x)
end
else
GtkOverlay(x...) = error("GtkOverlay is not available until Gtk3.2")
end


