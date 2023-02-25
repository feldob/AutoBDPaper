# selected feature combination from screening
features = ClusteringFeature[ sl_d, jc_d, jc_u ]

# summary files:
sutsummaries = joinpath.("results", "2_main_experiment", AutoBDPaper.sutnames .* "_all.csv")

# write all to disk
wtd = true

for sutsummary in sutsummaries
    sutname = first(match(r"^(.*)_all.csv$", basename(sutsummary)))
    setup = ClusteringSetup(sutsummary, sutname, features; rounds=100)
    summarize(setup; wtd)
end
