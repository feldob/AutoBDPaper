# OBS expects exactly 2 algs in comparison
function summary_main_quantitative(expdir::String)
    expfiles = expfilesof(expdir; incldir = false)
    sutnames = unique(sutnameof.(expfiles))
    secondalg, firstalg = unique(map(x -> split(x, "_")[end-4], expfiles))
    times = parse.(Int, unique(map(x -> split(x, "_")[end-1], expfiles)))

    df = DataFrame(sut = String[],
                    time = Int[],
                    algorithm = String[],
                    groundtruthsize = Int[],
                    found_mean = Float64[],
                    found_sd = Float64[],
                    found_unique = Int[])
    
    for sutname in sutnames
        sutname |> println

        local sut
        try
            sut = bve_suts[sutname]
        catch
            "results for sut by name $sutname cannot be found." |> println
            continue
        end

        expfiles_sut = expfilesof(expdir; sutname)

        for time in times
            
            df_all = CSV.read(joinpath(expdir, "$(sutname)_$(time)_all.csv"), DataFrame; types = String)
    
            h = filter(x -> contains(x, firstalg) && contains(x, "_$(time)_"), expfiles_sut)
            r = filter(x -> contains(x, secondalg) && contains(x, "_$(time)_"), expfiles_sut)
            
            entries_h = Vector{Integer}(undef, length(h))
            local df_h
            for (idx, expfile) in enumerate(h)
                res_frame = CSV.read(expfile, DataFrame; types = String)
                entries_h[idx] = nrow(res_frame)
    
                if @isdefined(df_h)
                    df_h = vcat(df_h, res_frame)  # append
                else
                    df_h = res_frame              # init
                end
                unique!(df_h, argnames(sut))
            end
    
            "average for $firstalg: $(mean(entries_h))"|> println
            
            entries_r = Vector{Integer}(undef, length(r))
            local df_r
            for (idx, expfile) in enumerate(r)
                res_frame = CSV.read(expfile, DataFrame; types = String)
                entries_r[idx] = nrow(res_frame)
    
                if @isdefined(df_r)
                    df_r = vcat(df_r, res_frame)  # append
                else
                    df_r = res_frame              # init
                end
                unique!(df_r, argnames(sut))
            end
    
            "average for $secondalg: $(mean(entries_r))"|> println
    
            i_h = map(Tuple, eachrow(df_h[:, argnames(sut)]))
            i_r = map(Tuple, eachrow(df_r[:, argnames(sut)]))
    
           push!(df, (sutname,time, firstalg, nrow(df_all), mean(entries_h), std(entries_h), length(setdiff(i_h,i_r))))
           push!(df, (sutname,time, secondalg, nrow(df_all), mean(entries_r), std(entries_r), length(setdiff(i_r,i_h))))
        end
    end
    
    CSV.write(joinpath(expdir, "direct_stats_all.csv"), df)
end

cts_criterion(x) = contains(x, "_cts_")

# OBS expects exactly 2 algs in comparison
function summary_screening(expdir::String)
    expfiles = expfilesof(expdir; incldir = false)
    sutnames = unique(map(x -> sutnameof(x), expfiles))
    secondalg, firstalg = unique(map(x -> split(x, "_")[end-4], expfiles)) # alphabetic, take lns first
    sss = unique(map(x -> split(x, "_")[end-3], expfiles))
    times = parse.(Int, unique(map(x -> split(x, "_")[end-1], expfiles)))

    df = DataFrame(time = Int[],
                    algorithm = String[],
                    cts = Bool[],
                    samplingstrategy = String[],
                    found_mean = Float64[],
                    found_sd = Float64[])

    for sutname in sutnames
        for ss in sss
            for cts in [true, false]
                cts_cond = cts ? cts_criterion : !cts_criterion
                expfiles_sut = expfilesof(expdir; sutname)

                for time in times

                    h = filter(x -> contains(x, "_$(firstalg)_") && contains(x, "_$(time)_"), expfiles_sut)
                    r = filter(x -> contains(x, "_$(secondalg)_") && contains(x, "_$(time)_"), expfiles_sut)

                    entries_h = Vector{Integer}(undef, length(h))
                    local df_h
                    for (idx, expfile) in enumerate(h)
                        res_frame = CSV.read(expfile, DataFrame; types = String)

                        res_frame = unique!(res_frame, [:output, :n_output])[:,[:output, :n_output]]
                        entries_h[idx] = nrow(res_frame)

                        if @isdefined(df_h)
                            df_h = vcat(df_h, res_frame)  # append
                        else
                            df_h = res_frame              # init
                        end
                        df_h = unique!(df_h)
                    end
                    
                    "average for $firstalg: $(mean(entries_h))"|> println
                    
                    entries_r = Vector{Integer}(undef, length(r))
                    local df_r
                    for (idx, expfile) in enumerate(r)
                        res_frame = CSV.read(expfile, DataFrame; types = String)

                        res_frame = unique!(res_frame, [:output, :n_output])[:,[:output, :n_output]]
                        entries_r[idx] = nrow(res_frame)

                        if @isdefined(df_r)
                            df_r = vcat(df_r, res_frame)  # append
                        else
                            df_r = res_frame              # init
                        end
                        df_r = unique!(df_r)
                    end
                    
                    "average for $secondalg: $(mean(entries_r))"|> println
                    
                    if !isnan(mean(entries_h))
                        push!(df, (time, firstalg, cts, ss, mean(entries_h), std(entries_h)))
                        push!(df, (time, secondalg, cts, ss, mean(entries_r), std(entries_r)))
                    end
                end
            end
        end
    end

    sort!(df, [:time, :algorithm, :samplingstrategy, :cts], rev = [false, true, true, false])

    CSV.write(joinpath(expdir, "screening_stats_all.csv"), df)
    return df
end

function combine_dfs(origin_name::String, result_dir::String, dirs::String...)
    dfs = map(d -> unique(CSV.read(joinpath(result_dir, d, origin_name), DataFrame)), dirs)
    return unique(vcat(dfs...))
end