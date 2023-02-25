sutnameof(expfile::String) = match(r"^(.*)_[A-Za-z]*_[A-Za-z]*_[A-Za-z]*_[A-Za-z]*_\d*_\d*.csv$", expfile)[1]
algof(expfile::String) = match(r"^.*_[A-Za-z]*_([A-Za-z]*)_[A-Za-z]*_[A-Za-z]*_\d*_\d*.csv$", expfile)[1]
timeof(expfile::String) = match(r"^.*_[A-Za-z]*_[A-Za-z]*_[A-Za-z]*_[A-Za-z]*_(\d*)_\d*.csv$", expfile)[1]

function expfilesof(expdir::String; sutname=r".*", alg=r"[A-Za-z]*", time=r"\d*", incldir=true)
    files = filter(x -> occursin(   r"^"    * sutname
                                    * r"_[A-Za-z]*_"
                                    * alg
                                    * r"_[A-Za-z]*_[A-Za-z]*_"
                                    * time
                                    * r"_\d*.csv$", x), readdir(expdir))
    return incldir ? joinpath.(expdir, files) : files
end

function expname(expdir::String, sut::String, OM::String, alg::String, ss::String, cts::String, exectime::Integer, repetition::Integer)
    return "$expdir/$(sut)_$(OM)_$(alg)_$(ss)$(cts)$(exectime)_$(repetition).csv"
end

function expname(expdir::String, sut::SUT, OM::Type{<:RelationalMetric}, alg, ss::Type{<:SamplingStrategy}, cts::Bool, exectime::Integer, repetition::Integer)
    cts_string = cts ? "_cts_" : "_"
    return expname(expdir, AutoBVA.name(sut), string(OM), string(alg), string(ss), cts_string, exectime, repetition)
end

function doexperiment(expdir, suts, exectimes, algorithms, repetitions, sss, ctss=[true], dryrun::Bool=true)
    
    mkpath(expdir) # create results path if it does not exist

    resfile = "$expdir/results.csv"

    resdf = DataFrame(sut=String[],
                        metric=String[],
                        algorithm=String[],
                        samplingstrategy=String[],
                        cts=Bool[],
                        repetition=Int64[],
                        time=Int64[],
                        iterations=Int64[])

    for sut in suts
        problem = SUTProblem(sut, fill(IntMutationOperators, numargs(sut)))
        for alg in algorithms
            dryrundone = !dryrun
            for exectime in exectimes
                for ss in sss
                    for cts in ctss
                        ss_param = map(n -> ss(argtypes(sut)[n], cts), 1:numargs(sut))
                        for repetition in 1:repetitions
                            params = ParamsDict(:Method => alg,
                                :MaxTime => exectime,
                                :SamplingStrategy => ss_param,
                                :CTS => cts)

                            res = bboptimize(problem; params...)

                            if !dryrundone
                                res = bboptimize(problem; params...)
                                dryrundone = true
                            end

                            ranked_candidates = rank_unique(res.method_output; output=true, incl_metric=true, filter=true, tosort=true)

                            _expname = expname(expdir, sut, ProgramDerivative, alg, ss, cts, exectime, repetition)
                            CSV.write(_expname, ranked_candidates)
                            restuple = [AutoBVA.name(sut), "ProgramDerivative", string(alg), string(ss), cts, repetition, exectime, BlackBoxOptim.iterations(res)]
                            push!(resdf, restuple)
                            CSV.write(resfile, resdf)
                        end
                    end
                end
            end
        end
    end
end