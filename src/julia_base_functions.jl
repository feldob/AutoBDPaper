#---------------
# methods
#---------------

# OBS this is limited to regular params, excluding keyword arguments

struct JMethod
    m::Method
    f::Function
end

args(jm::JMethod) = jm.m.sig.parameters[2:end]
name(jm::JMethod) = string(jm.m.name)

typeconsistent(p, type_constraint::Vector; allow_any::Bool=false) = !typeinconsistent(p, type_constraint; allow_any)

function typeinconsistent(p, type_constraint::Vector; allow_any::Bool=false)
    if p isa Union
        for p_inunion in Base.uniontypes(p)
            if typeinconsistent(p_inunion, type_constraint)
                return true
            end
        end
    end

    anycriterion = allow_any ? (p) -> p != Any : (p) -> true

    if anycriterion(p) && p ∉ type_constraint
        return true
    end
    return false
end

function jmethods(m::Module; type_constraint::Vector=[], allow_any::Bool=true)
    allnames = names(m; all = true, imported = true)
    "The total number of names in $m for Julia $VERSION is $(length(allnames))" |> println
    allfuncs = filter(f -> f isa Function, map(a -> getfield(m, a), allnames))
    "The number of functions in $m is $(length(allfuncs))" |> println

    allmethods = Dict()
    for f in allfuncs
        for m in methods(f)
            allmethods[m] = f
        end
    end

    allparams = Dict()
    for m in keys(allmethods)
        if  m.sig isa UnionAll
            # UnionAll ignored for this study
        else
            allparams[m] = m.sig.parameters[2:end]
        end
    end

    "The number of methods in $m is $(length(allmethods))" |> println

    type_methods = Dict()

    for m in keys(allparams)
        params = allparams[m]
        if isempty(params)
            continue
        end

        type_only = true
        for p in params
            if !typeconsistent(p, type_constraint; allow_any)
                type_only = false
                break
            end
        end

        if type_only
            type_methods[m] = allmethods[m]
        end
    end

    "The number of methods allowing for a combination of $(type_constraint) params only are $(length(type_methods))" |> println

    jms = map(m -> JMethod(m, type_methods[m]), collect(keys(type_methods)))
    return sort!(jms, by = name)
end

#---------------
# samples
#---------------

compatibletypes(::Type{<:AbstractString}) = [ AbstractString, String ]

function compatibletypes(type)
    if !(isabstracttype(type))
        return [type]
    end

    return ∪(compatibletypes.(subtypes(type))..., [type])
end

# assumed that all methods here have 1) same number of arguments and 2) compatible arguments (i.e. a winner can be derived on generalizability)
function most_general(v::Vector{JMethod})
    e = v[1]
    e_params = e.m.sig.parameters[2:end]

    for c in v[2:end]
        c_params = c.m.sig.parameters[2:end]
        for i in eachindex(c_params)
            e_param = e_params[i]
            c_param = c_params[i]
            if e_param isa Union || e_param isa UnionAll || c_param isa Union || c_param isa UnionAll
                continue
            elseif e_param <: c_param
                e = c
                break
            elseif c_param <: e_param
                continue
            elseif isabstracttype(e_param)
                if isabstracttype(c_param)
                    # set the one lexicographically right
                    if string(c_param) < string(e_param)
                        e = c
                    end
                else
                    # certainly keep the existing one, as the new one is "concrete"
                    continue
                end
            elseif isabstracttype(c_param) # e_param is concrete
                e = c
            elseif isconcretetype(e_param) && isconcretetype(c_param) # both are concrete
                if sizeof(c_param) > sizeof(e_param) # more representation size ~ more general
                    e = c
                end
            end
        end
    end

    return e
end

function reduce_to_most_general_method(v::Vector{JMethod})
    sort!(v, by = (x) -> x.m.line)
    if isempty(v)
        return v
    end

    names = unique(map(e -> nameof(e.f), v))
    elements = Dict()

    foreach(n -> elements[n] = JMethod[], names) # init the sets
    foreach(e -> push!(elements[nameof(e.f)], e), v) # include all entries into sets

    filtered_v = []
    for n in names
        f_e = most_general(elements[n])
        push!(filtered_v, f_e)
    end

    return sort!(filtered_v, by = m -> m.m.name)
end

# OBS must be called on the REPL
function load_samples()
    methods_ints = jmethods(Base; type_constraint=setdiff(compatibletypes(Integer), [Bool]), allow_any=true)
    methods_strings = jmethods(Base; type_constraint=compatibletypes(String), allow_any=true)
    methods_arrays = jmethods(Base; type_constraint=[Vector], allow_any=true)

    complexity_filter(methods) = filter(m -> m.f ∉ [(~), (!=), (!==), (&), (|), (+), (-), (^), (\), (/), (*), (<), (>), (//), (<<), (>>), (>>>), (==), (<=), (>=)], methods)
    visibility_filter(methods) = filter(m -> Base.isexported(Base, Symbol(m.f)), methods)
    rev_visibility_filter(methods) = filter(m -> !Base.isexported(Base, Symbol(m.f)), methods)
    param_size_filter(methods, amount) = filter(m -> length(m.m.sig.parameters) == amount + 1, methods)

    global methods_ints_1 = param_size_filter(methods_ints, 1) |> visibility_filter |> complexity_filter |> reduce_to_most_general_method
    global methods_ints_2 = param_size_filter(methods_ints, 2) |> visibility_filter |> complexity_filter |> reduce_to_most_general_method
    global methods_ints_3 = param_size_filter(methods_ints, 3) |> visibility_filter |> complexity_filter |> reduce_to_most_general_method

    global methods_strings_1 = param_size_filter(methods_strings, 1)
    global methods_arrays_1 = param_size_filter(methods_arrays, 1)

    global methods_ints_ne_1 = param_size_filter(methods_ints, 1) |> rev_visibility_filter |> complexity_filter |> reduce_to_most_general_method
    global methods_ints_ne_2 = param_size_filter(methods_ints, 2) |> rev_visibility_filter |> complexity_filter |> reduce_to_most_general_method
    global methods_ints_ne_3 = param_size_filter(methods_ints, 3) |> rev_visibility_filter |> complexity_filter |> reduce_to_most_general_method
end