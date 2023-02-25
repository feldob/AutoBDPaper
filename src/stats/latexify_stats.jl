
function propernaming!(df::DataFrame)
        replace!(df.algorithm, "lns" => "LNS")
        replace!(df.algorithm, "bcs" => "BCS")

        if "samplingstrategy" ∈ names(df)
            replace!(df.samplingstrategy, "UniformSampling" => "uniform")
            replace!(df.samplingstrategy, "BituniformSampling" => "bituniform")
        end
end

function latexify_screening()
    df = CSV.read(joinpath("results", "1_sampling_screening", "screening_stats_all.csv"), DataFrame, types = String)

    propernaming!(df)

    replace!(df.cts, "true" => "\\checkmark")
    replace!(df.cts, "false" => "")

    df[!, "found (μ ± σ)"] .= "\$" .* string.(parse.(Float64, df[:, :found_mean])) .* " \\pm " .* string.(round.(parse.(Float64, df[:, :found_sd]), digits=1)) .* "\$"

    select!(df, Not([:found_sd, :found_mean]))

    latexify(df, latex=false, env=:table) |> println
end

function latexify_summary(expdir::String, filename::String, outputfile::String)
    path = joinpath(expdir, filename)
    df = CSV.read(path, DataFrame, types = String)

    propernaming!(df)

    df[!, "found (μ ± σ)"] .= "\$" .* string.(parse.(Float64, df[:, :found_mean])) .* " \\pm " .* string.(round.(parse.(Float64, df[:, :found_sd]), digits=1)) .* "\$"

    select!(df, Not([:found_sd, :found_mean]))

    df_sut = groupby(df, :sut)

    buffer = IOBuffer()

    alg_time_filter(dfs,a,t) = filter(r -> r[:algorithm] == a && r[:time] == "$(t)", dfs)

    for dfs in df_sut
        println(buffer, "\\midrule")
        counter = 0
        for a in unique(dfs, :algorithm)[!, :algorithm]

            df_30 = alg_time_filter(dfs, a, 30)
            _30 = first(df_30)
            if counter == 0
                print(buffer, dfs[1,:sut])
            end
            print(buffer, " & $a & $(_30[:groundtruthsize]) & $(_30[end]) & $(_30[:found_unique])")

            df_600 = alg_time_filter(dfs, a, 600)
            if !isempty(df_600)
                _600 = first(df_600)
                print(buffer, " & $(_600[:groundtruthsize]) & $(_600[end]) & $(_600[:found_unique])")
            end
            println(buffer, "\\\\")
            counter += 1
        end
    end

    output = String(take!(buffer))
    println(output)
    if outputfile != ""
        open(joinpath(expdir, outputfile), "w") do io
            write(io, output)
        end
    end
end

latexify_summary_quantitative(expdir::String, outputfile::String="") = latexify_summary(expdir, "direct_stats_all.csv", outputfile)
latexify_summary_qualitative(expdir::String, outputfile::String="") = latexify_summary(expdir, "clustering_stats_all.csv", outputfile)

function inputvector(df::DataFrame, o_range)
    if length(o_range) == 1
        return df[:,o_range[1]]
    end

    v = fill("(", nrow(df))
    first = true
    for c in eachcol(df[:, o_range])
        if first 
            first = false
        else
            v = string.(v,",")
        end
        v = string.(v, c)
    end
    v = string.(v, ")")
    return v
end

function latexify_clustering_screening_scores()
    df = CSV.read(joinpath("results","2_main_experiment","clustering_screening", "bytecount_clustering_scores.csv"), DataFrame, types = String)

    sort!(df, [:score, :nclust], rev = true)
    df.id .= replace.(df.id, "-" => " + ")
    df.id .= replace.(df.id, "sl" => "\\textit{strlendist}")
    df.id .= replace.(df.id, "lv" => "Levenshtein")
    df.id .= replace.(df.id, "jc" => "Jaccard")
    df.id .= replace.(df.id, "_d" => " (WD)")
    df.id .= replace.(df.id, "_u" => " (U)")
    
    df_correct = DataFrame(id = df.id, silhouette=df.score, nclust=df.nclust)
    df_correct = df_correct[1:9, :]
    latexify(df_correct, latex=false, env=:table)    
end

function latexify_clustering_representatives(expdir::String, suts=AutoBDPaper.sutnames, outputfile::String="")

    buffer = IOBuffer()
    for s in suts
        df_o = CSV.read(joinpath(expdir, s * "_representatives.csv"), DataFrame; types = String)
        if isempty(df_o)
            println(buffer, "no representatives for sut \$$s\$ :(\n")
            continue
        end

        output_idx = findfirst(names(df_o) .== "output")
        numparams = output_idx-2
        param_idxs = 2:numparams+1
        # convert inputs to ints before sorting
        for i in 2:numparams
            try
                df_o[!,i] = parse.(BigInt, df_o[!, i])
            catch e
                println("no BigInt conversion before sorting because of incompatibilities - possibly Bool.")
            end
        end

        sort!(df_o, ["clustering", names(df_o)[param_idxs]...], rev=[true, fill(false, length(param_idxs))...])

        df = DataFrame()
        df.clustering = string.(1:nrow(df_o), " " , df_o.clustering)
        df.input1 = inputvector(df_o, param_idxs)
        df.output1 = df_o.output
        df.input2 = inputvector(df_o, output_idx+1:output_idx+numparams)
        df.output2 = df_o.n_output
        df.clustermembers = df_o.clustermembers
        df.bcs = df_o.bcs

        table_string = latexify(df, latex=false, env=:table)
        println(buffer, "SUT: \$$s\$\\\\")
        println(buffer, table_string)
    end

    output = String(take!(buffer))
    println(output)
    if outputfile != ""
        open(joinpath(expdir, outputfile), "w") do io
            write(io, output)
        end
    end
end

function latexify_silhouette_stats_julia_base(result_dir::String)
    df_stats = CSV.read(joinpath(result_dir, "juliabase_silhouette_stats.csv"), DataFrame)
    push!(df_stats, map(i -> df_stats[1,i] + df_stats[2,i], 1:ncol(df_stats)))
    df_stats.exporting = ["yes", "no", "all"]

    df_percentage = copy(df_stats)

    for cidx in 2:(ncol(df_percentage)-1)
        df_percentage[!, names(df_percentage)[cidx]] = string.(df_percentage[!, names(df_percentage)[cidx]])
    end

    for r in 1:nrow(df_percentage)
        for c in 2:(ncol(df_percentage)-1)
            df_percentage[r, c] = "$(df_stats[r , c]) ($(round(Int, df_stats[r , c]/df_percentage[r, :total]*100))\\%)"
        end
    end

    df_percentage |> println
    "------" |> println

    table_count = latexify(df_percentage, latex=false, env=:table)
    table_count |> println

    open(joinpath(result_dir, "juliabase_silhouette_stats.tex"), "w") do io
        write(io, table_count)
    end;
end

function latexify_quantitative_summary_julia_base(result_dir::String)
    df_stats = CSV.read(joinpath(result_dir, "juliabase_quant_summary.csv"), DataFrame)

    df_stats.per_run = "\$" .* string.(round.(Int, df_stats.bcs_per_run_mean)) .* " \\pm " .* string.(round.(Int, df_stats.bcs_per_run_sd)) .* "\$"
    df_stats.suts_success = string.(df_stats.suts_success) .* " (" .* string.(round.(Int, df_stats.suts_success./df_stats.suts_total .* 100)) .* "\\%)"

    select!(df_stats, Not([:bcs_per_run_mean, :bcs_per_run_sd]))

    df_stats |> println

    table = latexify(df_stats, latex=false, env=:table)
    table |> println

    open(joinpath(result_dir, "juliabase_quant_summary.tex"), "w") do io
        write(io, table)
    end;
end

function latexify_juliabase_top_silhouettes(result_dir::String, filename::String)
    df_stats = CSV.read(joinpath(result_dir, string(filename, ".csv")), DataFrame)

    df_stats.sutname = replace.(df_stats.sutname, "_" => "\\_")
    df_stats.sutname = map(r -> r.sutname * "($(r.params))", eachrow(df_stats))

    df_stats.total_clusters = df_stats.VE_clusters .+ df_stats.VV_clusters .+ df_stats.EE_clusters
    df_stats.bcs = "\$" .* string.(df_stats.bcs_mean) .* " \\pm " .* string.(round.(df_stats.bcs_sd, digits = 2)) .* "\$"

    select!(df_stats, Not([:params, :VV_points, :VE_points, :EE_points, :bcs_mean, :bcs_sd]))

    rounding(s::Symbol) = round.(df_stats[!,s], digits = 2)

    df_stats.VE = rounding(:VE)
    df_stats.VV = rounding(:VV)
    df_stats.EE = rounding(:EE)

    df_stats |> println

    table = latexify(df_stats, latex=false, env=:table)
    table |> println

    open(joinpath(result_dir, string(filename, ".tex")), "w") do io
        write(io, table)
    end;
end

function latexify_juliabase_top_silhouettes(result_dir::String)
    latexify_juliabase_top_silhouettes(result_dir, "juliabase_top_silhouettes_VV")
    latexify_juliabase_top_silhouettes(result_dir, "juliabase_top_silhouettes_VE")
    latexify_juliabase_top_silhouettes(result_dir, "juliabase_top_silhouettes_EE")
end

function latexify_summary_cluster_quality(result_dir::String)
    df = CSV.read(joinpath(result_dir, "silhouettes.csv"), DataFrame)

    select!(df, Not([:VV_points, :VE_points, :EE_points]))

    rounding(s::Symbol) = round.(df[!,s], digits = 2)

    df.VE = rounding(:VE)
    df.VV = rounding(:VV)
    df.EE = rounding(:EE)

    df = DataFrame(:SUT => df.sutname,
                    :ClVV => df.VV_clusters, :ClVE => df.VE_clusters, :ClEE => df.EE_clusters,
                    :VV => df.VV, :VE => df.VE, :EE => df.EE)
    df |> println

    table = latexify(df, latex=false, env=:table)
    table |> println

    open(joinpath(result_dir, "cluster_quality_stats.tex"), "w") do io
        write(io, table)
    end;
end

function clust_and_silhouette_stats_for(df::DataFrame, vg::Symbol, vgp::Symbol, vgc::Symbol)
    vg_good = filter(r -> r[vg] ≥ .6, df)
    vg_bad = filter(r -> r[vg] < .6 && r[vgp] > 0, df)

    vg_good_suts = nrow(vg_good)
    vg_good_total_mean = mean(vg_good[!, vgc])
    vg_good_total_sd = std(vg_good[!, vgc])
    vg_good_found_mean = mean(vg_good.found_mean)
    vg_good_found_sd = mean(vg_good.found_sd)

    vg_bad_suts = nrow(vg_bad)
    vg_bad_total_mean = mean(vg_bad[!, vgc])
    vg_bad_total_sd = std(vg_bad[!, vgc])
    vg_bad_found_mean = mean(vg_bad.found_mean)
    vg_bad_found_sd = std(vg_bad.found_sd)

    return vg_good_suts, vg_good_total_mean, vg_good_total_sd, vg_good_found_mean, vg_good_found_sd, vg_bad_suts, vg_bad_total_mean, vg_bad_total_sd, vg_bad_found_mean, vg_bad_found_sd
end

function latexify_juliabase_clusters_per_silhouettescore(result_dir::String, e_dir::String, ne_dir::String)
    df_e = CSV.read(joinpath(result_dir, e_dir, "silhouettes.csv"), DataFrame) |> unique
    df_ne = CSV.read(joinpath(result_dir, ne_dir, "silhouettes.csv"), DataFrame) |> unique
    df_e_cl = CSV.read(joinpath(result_dir, e_dir, "clustering_stats_all.csv"), DataFrame)
    df_ne_cl = CSV.read(joinpath(result_dir, ne_dir, "clustering_stats_all.csv"), DataFrame)

    df_stats = DataFrame(:exporting => Bool[],
                        :alg => String[],
                        :VV_good_suts => Int[],
                        :VV_good_total_mean => Float64[],
                        :VV_good_total_sd => Float64[],
                        :VV_good_mean => Float64[],
                        :VV_good_sd => Float64[],
                        :VV_bad_suts => Int[],
                        :VV_bad_total_mean => Float64[],
                        :VV_bad_total_sd => Float64[],
                        :VV_bad_mean => Float64[],
                        :VV_bad_sd => Float64[],
                        :VE_good_suts => Int[],
                        :VE_good_total_mean => Float64[],
                        :VE_good_total_sd => Float64[],
                        :VE_good_mean => Float64[],
                        :VE_good_sd => Float64[],
                        :VE_bad_suts => Int[],
                        :VE_bad_total_mean => Float64[],
                        :VE_bad_total_sd => Float64[],
                        :VE_bad_mean => Float64[],
                        :VE_bad_sd => Float64[],
                        :EE_good_suts => Int[],
                        :EE_good_total_mean => Float64[],
                        :EE_good_total_sd => Float64[],
                        :EE_good_mean => Float64[],
                        :EE_good_sd => Float64[],
                        :EE_bad_suts => Int[],
                        :EE_bad_total_mean => Float64[],
                        :EE_bad_total_sd => Float64[],
                        :EE_bad_mean => Float64[],
                        :EE_bad_sd => Float64[])

    rename!(df_ne,:sutname => :sut)
    rename!(df_e,:sutname => :sut)

    for triple in [(df_ne, df_ne_cl, false), (df_e, df_e_cl, true)]
        df, df_cl, type = triple
        df_all = innerjoin(df, df_cl, on = [:sut, :params])

        for alg in unique(df_all.algorithm)
            df_cl_alg = filter(r -> r.algorithm == alg, df_all)

            vv = clust_and_silhouette_stats_for(df_cl_alg, :VV, :VV_points, :VV_clusters)
            ve = clust_and_silhouette_stats_for(df_cl_alg, :VE, :VE_points, :VE_clusters)
            ee = clust_and_silhouette_stats_for(df_cl_alg, :EE, :EE_points, :EE_clusters)

            _row = (type, alg, vv..., ve..., ee...)
            push!(df_stats, _row)
        end
    end

    df_stats.VV_good_clusters = string.("\$", round.(df_stats.VV_good_total_mean, digits = 2)) .* " \\pm " .* string.(round.(df_stats.VV_good_total_sd, digits = 2), "\$")
    df_stats.VV_good = string.("\$", round.(df_stats.VV_good_mean, digits = 2)) .* " \\pm " .* string.(round.(df_stats.VV_good_sd, digits = 2), "\$")

    df_stats.VV_bad_clusters = string.("\$", round.(df_stats.VV_bad_total_mean, digits = 2)) .* " \\pm " .* string.(round.(df_stats.VV_bad_total_sd, digits = 2), "\$")
    df_stats.VV_bad = string.("\$", round.(df_stats.VV_bad_mean, digits = 2)) .* " \\pm " .* string.(round.(df_stats.VV_bad_sd, digits = 2), "\$")

    df_stats.VE_good_clusters = string.("\$", round.(df_stats.VE_good_total_mean, digits = 2)) .* " \\pm " .* string.(round.(df_stats.VE_good_total_sd, digits = 2), "\$")
    df_stats.VE_good = string.("\$", round.(df_stats.VE_good_mean, digits = 2)) .* " \\pm " .* string.(round.(df_stats.VE_good_sd, digits = 2), "\$")

    df_stats.VE_bad_clusters = string.("\$", round.(df_stats.VE_bad_total_mean, digits = 2)) .* " \\pm " .* string.(round.(df_stats.VE_bad_total_sd, digits = 2), "\$")
    df_stats.VE_bad = string.("\$", round.(df_stats.VE_bad_mean, digits = 2)) .* " \\pm " .* string.(round.(df_stats.VE_bad_sd, digits = 2), "\$")

    df_stats.EE_good_clusters = string.("\$", round.(df_stats.EE_good_total_mean, digits = 2)) .* " \\pm " .* string.(round.(df_stats.EE_good_total_sd, digits = 2), "\$")
    df_stats.EE_good = string.("\$", round.(df_stats.EE_good_mean, digits = 2)) .* " \\pm " .* string.(round.(df_stats.EE_good_sd, digits = 2), "\$")

    df_stats.EE_bad_clusters = string.("\$", round.(df_stats.EE_bad_total_mean, digits = 2)) .* " \\pm " .* string.(round.(df_stats.EE_bad_total_sd, digits = 2), "\$")
    df_stats.EE_bad = string.("\$", round.(df_stats.EE_bad_mean, digits = 2)) .* " \\pm " .* string.(round.(df_stats.EE_bad_sd, digits = 2), "\$")

    df_stats |> println

    df_final = select(df_stats, [:exporting, :alg, :VV_good_clusters, :VV_bad_clusters, :VE_good_clusters, :VE_bad_clusters, :EE_good_clusters, :EE_bad_clusters, :VV_good, :VV_bad, :VE_good, :VE_bad, :EE_good, :EE_bad])
    table = latexify(df_final, latex=false, env=:table)
    table |> println

    open(joinpath(result_dir, "juliabase_clustesr_per_silhouettescore.tex"), "w") do io
        write(io, table)
    end;
end
