function reduce_if_noisy!(df::DataFrame, expfile::String)
    "reduce: $expfile" |> println
    gfs = groupby(df, [:outputtype, :n_outputtype])
    df_new = similar(df, 0)

    for gf in gfs
        gf_interesting = filter(x -> x.count > 1, gf)
        append!(df_new, gf_interesting)

        if nrow(gf_interesting) < 1000
            n_space = 1000 - nrow(gf_interesting)
            gf_boring = filter(x -> x.count == 1, gf)

            if n_space < nrow(gf_boring)
                idxs_boring = sample(1:nrow(gf_boring), n_space, replace = false)
                gf_boring = gf_boring[idxs_boring, :]
            end

            append!(df_new, gf_boring)
        end
    end

    # permanently use
    CSV.write(expfile, df_new)
    if nrow(df) > nrow(df_new)
        CSV.write(expfile * "_ORIGINAL", df)
    end

    return df_new
end

function singlesummary(expfiles::AbstractVector{<:AbstractString}, outputfile::String="")
    local df
    for expfile in expfiles
        res_frame = CSV.read(expfile, DataFrame; types = String)
        if isempty(res_frame)
            if !@isdefined(df)
                df = res_frame
            end
        else
            res_frame.count = parse.(Int64, res_frame.count)
            res_frame = reduce_if_noisy!(res_frame, expfile)

            df = @isdefined(df) ? vcat(df, res_frame) : res_frame

            gr = groupby(df, setdiff(names(df), ["count"]))
            df = combine(gr, :count => sum => :count)
        end
    end

    if @isdefined(df)
        args = names(df)[1:findfirst(x -> x == "output", names(df))-1]

        sort!(df, args)
        if outputfile != ""
            CSV.write(outputfile, df)
        end

        return df
    end

    return nothing
end

function singlefilesummary(expdir::String; wtd=false)

    expfiles = expfilesof(expdir, incldir = false)
    sutnames = sutnameof.(expfiles) |> unique
    algs = algof.(expfiles) |> unique
    times = timeof.(expfiles) |> unique

    for sutname in sutnames
        filestart = joinpath(expdir, sutname)
        for time in times
            for alg in algs
                expfiles = expfilesof(expdir; sutname, alg, time)
                outputfile = wtd ? "$(filestart)_$(alg)_$(time)_all.csv" : ""
                singlesummary(expfiles, outputfile)
            end
            expfiles = expfilesof(expdir; sutname, time)
            outputfile = wtd ? "$(filestart)_$(time)_all.csv" : ""
            singlesummary(expfiles, outputfile)
        end
        for alg in algs
            expfiles = expfilesof(expdir; sutname, alg)
            outputfile = wtd ? "$(filestart)_$(alg)_all.csv" : ""
            singlesummary(expfiles, outputfile)
        end
        expfiles = expfilesof(expdir; sutname)
        outputfile = wtd ? "$(filestart)_all.csv" : ""
        singlesummary(expfiles, outputfile)
    end
end
