function uniqueclusters!(df::DataFrame)
    if isempty(df)
        return df
    end

    gdfs = groupby(df, :clustering)

    maxnow = 0
    for gdf in gdfs
        foreach(r -> r[:cluster] += maxnow, eachrow(gdf))
        maxnow = maximum(gdf[!, :cluster])
    end

    return df
end

# expects same :clustering, :cluster combinations
function uniqueclusters!(df1::DataFrame, df2::DataFrame)
    df1.cluster = parse.(Int64, df1.cluster)
    df2.cluster = parse.(Int64, df2.cluster)

    combs = unique(df1, [:clustering, :cluster])

    df1.temp_cluster = df1.cluster |> copy
    df2.temp_cluster = df2.cluster |> copy

    for (idx,comb) in enumerate(eachrow(combs))
        foreach(r -> r.cluster == comb.cluster && r.clustering == comb.clustering ? r.temp_cluster = idx : nothing, eachrow(df1))
        foreach(r -> r.cluster == comb.cluster && r.clustering == comb.clustering ? r.temp_cluster = idx : nothing, eachrow(df2))
    end

    df1.cluster = df1.temp_cluster
    df2.cluster = df2.temp_cluster

    select!(df1, Not(:temp_cluster))
    select!(df2, Not(:temp_cluster))

    sort!(df1, :cluster)
    sort!(df2, :cluster)
end

function unique_clusterings(exps::Vector, lookup::Dict{DataFrameRow, Int64})
    covered = Vector(undef, length(exps))
    for (idx, exp) in enumerate(exps)
        res_frame = CSV.read(exp, DataFrame; types = String)
        res_frame = res_frame[:, Not(:count)]

        try
            covered[idx] = unique!([ lookup[v] for v in eachrow(res_frame) ])
        catch
            covered[idx] = []
            "sut seems to be non-deterministic :(" |> println
        end
    end
    return covered
end

function summary_main_qualitative(expdir::String)
    clust_ready =  filter(f -> occursin(r".*_clustering.csv$", f), readdir(expdir))
    
    expfiles_all = expfilesof(expdir)
    times = parse.(Int, unique(map(x -> split(x, "_")[end-1], expfiles_all)))
    sss = unique(map(x -> split(x, "_")[end-3], expfiles_all))

    df_res = DataFrame(sut = String[],
                    time = Int[],
                    strategy = String[],
                    algorithm = String[],
                    groundtruthsize = Int[],
                    found_mean = Float64[],
                    found_sd = Float64[],
                    found_unique = Int[])

    for clust_file in clust_ready
        sutname = first(match.(r"^(.*)_clustering.csv$", clust_file))
        sutname |> println

        df_clusterings = CSV.read(joinpath(expdir, clust_file), DataFrame; types = String)
        df_clusterings.cluster = parse.(Int, df_clusterings.cluster)
        df_clusterings = uniqueclusters!(df_clusterings)
        n_total = isempty(df_clusterings) ? 0 : maximum(df_clusterings.cluster)

        clust_lookup = Dict{DataFrameRow, Int64}()
        df_raw = df_clusterings[:,1:end-3] # fifth is count - remove too
        foreach(e -> clust_lookup[e[2]] = df_clusterings[e[1], :][:cluster], enumerate(eachrow(df_raw)))

        for time in times
            for ss in sss
                bcs = expfilesof(expdir; sutname, alg="bcs", time = string(time))
                lns = expfilesof(expdir; sutname, alg="lns", time = string(time))

                bcs_covered = unique_clusterings(bcs, clust_lookup)
                lns_covered = unique_clusterings(lns, clust_lookup)

                bcs_mean = isempty(bcs_covered) ? 0.0 : mean(length.(bcs_covered))
                bcs_std = isempty(bcs_covered) ? 0.0 : std(length.(bcs_covered))

                lns_mean = isempty(lns_covered) ? 0.0 : mean(length.(lns_covered))
                lns_std = isempty(lns_covered) ? 0.0 : std(length.(lns_covered))

                bcs_all = unique(vcat(bcs_covered...))
                lns_all = unique(vcat(lns_covered...))

                bcs_unique = setdiff(bcs_all, lns_all)
                lns_unique = setdiff(lns_all, bcs_all)

                "$time, $ss:" |> println
                "bcs coverage: $bcs_mean ± $bcs_std" |> println
                "bcs unique: $(length(bcs_unique))" |> println
                "lns coverage: $lns_mean ± $lns_std" |> println
                "lns unique: $(length(lns_unique))" |> println

                push!(df_res, (sutname,time, ss, "bcs", n_total, bcs_mean, bcs_std, length(bcs_unique)))
                push!(df_res, (sutname,time, ss, "lns", n_total, lns_mean, lns_std, length(lns_unique)))
            end
        end
    end

    CSV.write(joinpath(expdir, "clustering_stats_all.csv"), df_res)
end

function lookupcolumns_names(df::DataFrame)
    output_idx = findfirst(names(df) .== "output")
    names_left = vcat(names(df)[1:output_idx-1], ["output"])
    names_right = map(n -> "n_$n", names_left)
    return vcat(names_left, names_right)
end

# for each representative candidate, get number of covered entries per each cluster
function incl_cluster_coverage(clusterings_file::String, exp_file::String, df_repr::DataFrame)
    df_clusterings = CSV.read(clusterings_file, DataFrame; types = String)
    df_results = CSV.read(exp_file, DataFrame; types = String)

    uniqueclusters!(df_clusterings, df_repr)

    clust_lookup = Dict{DataFrameRow, Int64}()

    lnames = AutoBDPaper.lookupcolumns_names(df_clusterings)

    df_raw = df_clusterings[:,lnames]
    foreach(e -> clust_lookup[e[2]] = df_clusterings[e[1], :][:cluster], enumerate(eachrow(df_raw)))

    df_repr.bcs = zeros(Integer, nrow(df_repr))

    df_results_raw = df_results[:, lnames]
    for r in eachrow(df_results_raw)
        try
            df_repr.bcs[clust_lookup[r]] += 1
        catch

            # no remedy if the sut is non-deterministic - simply dont count up anywhere.
        end
    end

    return df_repr
end

function cluster_representatives(clust_dir::AbstractString, sutname::AbstractString)
    clust_path = joinpath(clust_dir, sutname * "_clustering.csv")
    if !isfile(clust_path)
        return DataFrame() # no representatives
    end

    df_o = loadsummary(clust_path)
    if isempty(df_o)
        return df_o
    end

    df_o = df_o[:,Not([:datatype, :n_datatype, :outputtype, :n_outputtype, :metric])]

    gfs = groupby(df_o, [:clustering, :cluster]) # create grouping per clustering and cluster

    local df_final::DataFrame
    for gf in gfs
        df = DataFrame(gf)
        df.combined_length = length.(df.output) .+ length.(df.n_output)
        sort!(df, :combined_length)

        lns_shortest = DataFrame(first(df)) # extract a shortest variant
        lns_shortest.clustermembers = [ nrow(df) ]
        lns_shortest.memberhits = [ sum(parse.(Int64, df.count)) ]
        if @isdefined(df_final)
            df_final = vcat(df_final, lns_shortest) # combine shortest into common dataframe again
        else
            df_final = lns_shortest
        end
    end

    sort!(df_final, [:clustering, :combined_length])
    return hcat(DataFrame(clustering = df_final[:,:clustering]), df_final[:,Not([:clustering, :combined_length, :memberhits, :count])])
end

function summary_cluster_representatives(expdir::String, sutname::String)
    df = cluster_representatives(expdir, sutname)

    if !isempty(df)
        clustfile = joinpath(expdir, sutname * "_clustering.csv")
        bcsfile = joinpath(expdir, sutname * "_bcs_all.csv")
        df = incl_cluster_coverage(clustfile, bcsfile, df)
    end

    CSV.write(joinpath(expdir, sutname * "_representatives.csv"), df)
end

function summary_cluster_representatives(expdir::String, sutnames::Vector{String})
    for sutname in sutnames
        summary_cluster_representatives(expdir, sutname)
    end
end

const GST = .6 # good silhouette threshold

function stats_validitygroup(df::DataFrame, vgp::Symbol, vg::Symbol)
    #ve_f = filter(r -> r[vgp] == 0, df) |> nrow
    ve_b = filter(r -> r[vgp] > 0 && r[vg] < .6, df) |> nrow
    ve_g = filter(r -> r[vgp] > 0 && r[vg] ≥ .6, df) |> nrow
    return (ve_b, ve_g)
end

function extract_clustering_stats_julia_base(result_dir::String, e_dir::String, ne_dir::String)
    df_e = CSV.read(joinpath(result_dir, e_dir, "silhouettes.csv"), DataFrame) |> unique
    df_ne = CSV.read(joinpath(result_dir, ne_dir, "silhouettes.csv"), DataFrame) |> unique

    df_stats = DataFrame("exporting" => Bool[],
                            #"VE_fail" => Int[],
                            "VE_bad" => Int[],
                            "VE_good" => Int[],
                            #"VV_fail" => Int[],
                            "VV_bad" => Int[],
                            "VV_good" => Int[],
                            #"EE_fail" => Int[],
                            "EE_bad" => Int[],
                            "EE_good" => Int[],
                            "total_good" => Int[],
                            "total" => Int[])

    for pair in [(df_ne, false), (df_e, true)]
        df, type = pair
        ve = stats_validitygroup(df, :VE_points, :VE)
        vv = stats_validitygroup(df, :VV_points, :VV)
        ee = stats_validitygroup(df, :EE_points, :EE)

        total = nrow(df)
        total_good = filter(r -> r[:VE] ≥ GST || r[:VV] ≥ GST || r[:EE] ≥ GST, df) |> nrow
        _row = (type, ve... ,vv..., ee..., total_good, total)
        push!(df_stats, _row)
    end

    CSV.write(joinpath(result_dir, "juliabase_silhouette_stats.csv"), df_stats)
end

function extract_clusterings_julia_base(result_dir::String, e_dir::String, ne_dir::String)
    df_all = combine_dfs("silhouettes.csv", result_dir, e_dir, ne_dir)
    df_clust_stats = combine_dfs("clustering_stats_all.csv", result_dir, e_dir, ne_dir)

    interesting_clustering(r) = .6 < r.VE < 1 && .6 < r.VV < 1 && r.VV_points > 100 && r.VE_points > 100
    df_all = filter(interesting_clustering, df_all)
    sort!(df_all, [:VE, :VV, :EE], rev = true)

    df_all.bcs_mean = Vector{Float64}(undef, nrow(df_all))
    df_all.bcs_sd = Vector{Float64}(undef, nrow(df_all))
    for (idx, r_silh) in enumerate(eachrow(df_all))
        r_clust = filter(r -> r.algorithm == "bcs" && r_silh.sutname == r.sut && r.params == r_silh.params, df_clust_stats) |> first
        df_all.bcs_mean[idx] = r_clust.found_mean
        df_all.bcs_sd[idx] = r_clust.found_sd
    end

    return df_all
end

function extract_top_clusterings_julia_base(result_dir::String, e_dir::String, ne_dir::String)
    df_all = extract_clusterings_julia_base(result_dir, e_dir, ne_dir)

    sort!(df_all, :VE, rev = true)
    CSV.write(joinpath(result_dir, "juliabase_top_silhouettes_VE.csv"), df_all[1:10, :])
    sort!(df_all, :VV, rev = true)
    CSV.write(joinpath(result_dir, "juliabase_top_silhouettes_VV.csv"), df_all[1:10, :])
    sort!(df_all, :EE, rev = true)
    CSV.write(joinpath(result_dir, "juliabase_top_silhouettes_EE.csv"), df_all[1:10, :])
end