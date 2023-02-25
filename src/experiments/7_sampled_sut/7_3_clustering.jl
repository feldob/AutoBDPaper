# selected feature combination from screening
features = ClusteringFeature[ sl_d, jc_d, jc_u ]

sutnames = map(s -> AutoBVA.name(s), suts)

# summary files:
sutsummaries = joinpath.(expdir, sutnames .* "_all.csv")

# write all to disk
wtd = true

for sutsummary in sutsummaries
    sutname = first(match(r"^(.*)_all.csv$", basename(sutsummary)))
    if isfile(sutsummary)
        sutname |> println
        setup = ClusteringSetup(sutsummary, sutname, features; rounds=100)
        summarize(setup; wtd)
    else
        "summary for sut $sutname cannot be found" |> println
    end
end
