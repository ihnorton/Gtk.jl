#!/usr/bin/env julia

import Clang, Clang.cindex
include("gtk_list_gen.jl")
include("gtk_get_set_gen.jl")
include("gtk_consts_gen.jl")

function without_linenums!(ex::Expr)
    linenums_filter(x,ex) = true
    linenums_filter(x::LineNumberNode,ex) = false
    linenums_filter(x::Expr,ex) = x.head !== :line
    linenums_filter(x::Nothing,ex) = ex.head !== :block
    filter!((x)->linenums_filter(x,ex), ex.args)
    for arg in ex.args
        if isa(arg,Expr)
            without_linenums!(arg)
        end
    end
    ex
end

gtk_libdir = "/opt/local/lib"

toplevels = {}
cppargs = []
let gtk_version = Gtk.gtk_version
    header = joinpath(gtk_libdir,"..","include","gtk-$gtk_version.0","gtk","gtk.h")
    args = ASCIIString[split(readall(`$(joinpath(gtk_libdir,"..","bin","pkg-config")) --cflags gtk+-$gtk_version.0`),' ')...,cppargs...]
    global gtk_h, gtk_macro_h
    cd(JULIA_HOME) do
        gtk_h = cindex.parse_header(header, diagnostics=true, args=args, flags=0x41)
    end
    gboxpath = "gbox$(gtk_version)"
    gconstspath = "gconsts$(gtk_version)"
    cachepath = "gtk$(gtk_version)"

    g_types = gen_g_type_lists(gtk_h)
    for z in g_types
        for (s, ex) in z
            without_linenums!(ex)
        end
    end

    body = Expr(:block,
        Expr(:import, :., :., :Gtk),
        Expr(:import, :., :., :Gtk, :GObject),
    )
    gbox = Expr(:toplevel,Expr(:module, true, :GAccessor, body))
    count_fcns = gen_get_set(body, gtk_h)
    println("Generated $gboxpath with $count_fcns function definitions")
    without_linenums!(gbox)

    body = Expr(:block)
    gconsts = Expr(:toplevel,Expr(:module, true, :GConstants, body))
    count_consts = gen_consts(body, gtk_h)
    println("Generated $gconstspath with $count_consts constants")
    without_linenums!(gconsts)

    open(joinpath(splitdir(@__FILE__)[1], gboxpath), "w") do cache
        Base.println(cache,"quote")
        Base.show_unquoted(cache, gbox)
        println(cache)
        Base.println(cache,"end")
    end
    open(joinpath(splitdir(@__FILE__)[1], gconstspath), "w") do cache
        Base.println(cache,"quote")
        Base.show_unquoted(cache, gconsts)
        println(cache)
        Base.println(cache,"end")
    end
    open(joinpath(splitdir(@__FILE__)[1], "$(cachepath)_julia_ser$(Base.ser_version)"), "w") do cache
        serialize(cache, gbox)
        serialize(cache, gconsts)
    end
    push!(toplevels,(gbox,gconsts,g_types,gtk_h))
end
toplevels

