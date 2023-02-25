
function summary_all_suts(expdir::String, suts::Vector)

    df = DataFrame()
    df.sutname = AutoBVA.name.(suts)
    df.numargs = AutoBVA.numargs.(suts)
    df.argtypes = join.(AutoBVA.argtypes.(suts), ',')
    df.executed .= false
    df.bcs_bc_mean .= 0.0
    df.bcs_bc_std .= 0.0
    df.lns_bc_mean .= 0.0
    df.lns_bc_std .= 0.0

    df.bcs_clusters_mean .= 0.0
    df.bcs_clusters_std .= 0.0
    df.lns_clusters_mean .= 0.0
    df.lns_clusters_std .= 0.0

    df.bcs_clusters_unique .= 0
    df.lns_clusters_unique .= 0
    df.total_clusters .= 0
    
    clustering_df = CSV.read(joinpath(expdir, "clustering_stats_all.csv"), DataFrame)
    
    for (idx, sut) in enumerate(suts)
        expfiles = expfilesof(expdir)

        expfiles = filter(x -> sutnameof(basename(x)) == AutoBVA.name(sut), expfiles) # ensure no false positives are added ("e.g. count for count_zeros")
        if !isempty(expfiles)
            df.executed[idx] = true

            expfiles_lns = CSV.read.(filter(x -> contains(x, "_lns_"), expfiles), DataFrame)
            expfiles_bcs = CSV.read.(filter(x -> contains(x, "_bcs_"), expfiles), DataFrame)

            nrows_lns = nrow.(expfiles_lns)
            nrows_bcs = nrow.(expfiles_bcs)

            df.lns_bc_mean[idx] = mean(nrows_lns)
            df.lns_bc_std[idx] = std(nrows_lns)

            df.bcs_bc_mean[idx] = mean(nrows_bcs)
            df.bcs_bc_std[idx] = std(nrows_bcs)

            clust_stats_df = filter(r -> r["sut"] == AutoBVA.name(sut), clustering_df)
            if !isempty(clust_stats_df)
                for r in eachrow(clust_stats_df)
                    alg = r["algorithm"]

                    df[!, "$(alg)_clusters_mean"][idx] = r["found_mean"]
                    df[!, "$(alg)_clusters_std"][idx] = r["found_sd"]
                    df[!, "$(alg)_clusters_unique"][idx] = r["found_unique"]
                end
            end

            clust_df = CSV.read(joinpath(expdir, AutoBVA.name(sut) * "_clustering.csv"), DataFrame)
            if !isempty(clust_df)
                df.total_clusters[idx] = length(groupby(clust_df, [:clustering, :cluster]))
            end
        end
    end

    CSV.write(joinpath(expdir, "Base_stats_all.csv"), df)
end

function expdirs_for(dirstart::String)
    filter(d -> startswith(d, dirstart) && isdir(joinpath("results", d))  && length(d) == length(dirstart) + 1, readdir("results"))
end

function combine_all_silhouettes(dirstart::String)
    expdirs = expdirs_for(dirstart)
    local df_all
    for expdir in expdirs
        silh_path = joinpath("results", expdir, "silhouettes.csv")
        if isfile(silh_path)
            df = CSV.read(silh_path, DataFrame)
            n_params = parse(Int, expdir[end])
            df.params = fill(n_params, nrow(df))
            df_all = (@isdefined df_all) ? vcat(df_all, df) : df
        end
    end

    gdfs = groupby(df_all, [:sutname, :params])
    df_all = combine(gdfs, names(df_all) .=> first; renamecols = false)

    output_dir = joinpath("results", "summary_" * dirstart)
    mkpath(output_dir)
    output_path = joinpath(output_dir, "silhouettes.csv")
    CSV.write(output_path, df_all)
end

function combine_all_stats(statsfile::String, dirstart::String)
    expdirs = expdirs = expdirs_for(dirstart)
    local df_all
    for expdir in expdirs
        stats_path = joinpath("results", expdir, statsfile)
        if isfile(stats_path)
            df = CSV.read(stats_path, DataFrame)
            n_params = parse(Int, expdir[end])
            df.params = fill(n_params, nrow(df))
            df_all = (@isdefined df_all) ? vcat(df_all, df) : df
        end
    end

    gdfs = groupby(df_all, [:sut, :params, :algorithm])
    df_all = combine(gdfs, names(df_all) .=> first; renamecols = false)

    output_dir = joinpath("results", "summary_" * dirstart)
    mkpath(output_dir)
    output_path = joinpath(output_dir, statsfile)
    CSV.write(output_path, df_all)
end

combine_all_clusters_stats(dirstart::String) = combine_all_stats("clustering_stats_all.csv", dirstart)
combine_all_direct_stats(dirstart::String) = combine_all_stats("direct_stats_all.csv", dirstart)

function mv_representatives_to_summary(dirstart::String)
    sum_path = joinpath("results", "summary_" * dirstart, "representatives")
    mkpath(sum_path)
    expdirs = expdirs = expdirs_for(dirstart)
    for expdir in expdirs
        n_params = split(expdir, '_')[end]
        exppath = joinpath("results", expdir)
        reprs = filter(d -> occursin(r".*_representatives.csv$", d), readdir(exppath))
        for repr in reprs
            from = joinpath(exppath, repr)
            parts = split(basename(repr), "_")
            to_basename = join(vcat(parts[1:end-1], n_params, parts[end]), "_")
            to = joinpath(sum_path, to_basename)
            if isfile(to)
                "$to already exists" |> println
            else
                cp(from, to)
            end
        end
    end
end

function mv_tex_to_summary(dirstart::String)
    sum_path = joinpath("results", "summary_" * dirstart)
    mkpath(sum_path)
    expdirs = expdirs = expdirs_for(dirstart)
    for expdir in expdirs
        exppath = joinpath("results", expdir)
        texstats = filter(d -> occursin(r".*.tex$", d), readdir(exppath))
        for repr in texstats
            from = joinpath(exppath, repr)
            to = joinpath(sum_path, basename(repr))
            if isfile(to)
                "$to already exists" |> println
            else
                cp(from, to)
            end
        end
    end
end

function extract_quantitative_summary_julia_base(result_dir::String, e_dir::String, ne_dir::String)
    df_e = CSV.read(joinpath(result_dir, e_dir, "direct_stats_all.csv"), DataFrame)
    df_ne = CSV.read(joinpath(result_dir, ne_dir, "direct_stats_all.csv"), DataFrame)

    df_stats = DataFrame("exporting" => Bool[],
                            "algorithm" => String[],
                            "suts_total" => Int[],
                            "suts_success" => Int[],
                            "bcs_per_run_mean" => Float64[],
                            "bcs_per_run_sd" => Float64[])

    for pair in [(df_ne, false), (df_e, true)]
        df, type = pair
        total = nrow(unique(df, [:sut, :params]))
        for alg in unique(df.algorithm)
            df_success = filter(r -> r.algorithm == alg && r.found_mean > 0, df)
            success = nrow(df_success)
            bcs_mean = mean(df_success.found_mean)
            bcs_sd = std(df_success.found_sd)
            _row = (type, alg, total, success, bcs_mean, bcs_sd)
            push!(df_stats, _row)
        end
    end

    CSV.write(joinpath(result_dir, "juliabase_quant_summary.csv"), df_stats)
end