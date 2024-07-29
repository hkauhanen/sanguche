using CategoricalArrays, DataFrames, Measures, Serialization, StatsPlots


wals = deserialize("../results/wals/results.jls")
grambank = deserialize("../results/grambank/results.jls")


wals.okay = categorical(wals.okay, ordered=true)
levels!(wals.okay, ["interacting", "unknown", "non-interacting"])
grambank.okay = categorical(grambank.okay, ordered=true)
levels!(grambank.okay, ["interacting", "unknown", "non-interacting"])


okay_colours = [:green :blue :red]

p1 = @df wals boxplot(:okay, :H_pref .- :H, group=:okay, fillalpha=0.4, alpha=0.7, outliers=false, label=false, color=^(okay_colours))
#@df wals scatter!(:okay, :H_pref .- :H, group=:okay, legend=false, color=^(okay_colours))
title!("(A) Overrepresented types, WALS")
#ylims!(extrema(vcat(data.H_pref .- data.H, data.H_dispref .- data.H)))
ylims!(-0.3, 0.4)
ylabel!("Neighbourhood entropy differential (Δ)")

p2 = @df wals boxplot(:okay, :H_dispref .- :H, group=:okay, fillalpha=0.3, alpha=1.0, outliers=false, label=false, color=^(okay_colours))
#@df wals scatter!(:okay, :H_dispref .- :H, group=:okay, legend=false, color=^(okay_colours))
title!("(B) Underrepresented types, WALS")
#ylims!(extrema(vcat(data.H_pref .- data.H, data.H_dispref .- data.H)))
ylims!(-0.3, 0.4)
#ylabel!("normalized neighbourhood entropy")

p3 = @df grambank boxplot(:okay, :H_pref .- :H, group=:okay, fillalpha=0.4, alpha=0.7, outliers=false, label=false, color=^(okay_colours))
#@df wals scatter!(:okay, :H_pref .- :H, group=:okay, legend=false, color=^(okay_colours))
title!("(C) Overrepresented types, Grambank")
#ylims!(extrema(vcat(data.H_pref .- data.H, data.H_dispref .- data.H)))
ylims!(-0.3, 0.4)
ylabel!("Neighbourhood entropy differential (Δ)")

p4 = @df grambank boxplot(:okay, :H_dispref .- :H, group=:okay, fillalpha=0.3, alpha=1.0, outliers=false, label=false, color=^(okay_colours))
#@df wals scatter!(:okay, :H_dispref .- :H, group=:okay, legend=false, color=^(okay_colours))
title!("(D) Underrepresented types, Grambank")
#ylims!(extrema(vcat(data.H_pref .- data.H, data.H_dispref .- data.H)))
ylims!(-0.3, 0.4)
#ylabel!("normalized neighbourhood entropy")


plot(p1, p2, p3, p4, 
     layout=(2,2),
     left_margin=[10mm 0mm], 
     right_margin=[0mm 0mm], 
     bottom_margin=[5mm 5mm], 
     top_margin=[2mm 2mm], 
     aspect_ratio=6.0,
     titlefontsize=11,
     titlelocation=:left,
     size=(900,1000),
     dpi=200)

#xlabel!("Feature pair class")


try
  mkdir("../results/plots")
catch e
end

savefig("../results/plots/boxplot.png")

trim = false
bw = 50.0

p1 = @df wals density(:mean_distance, label="WALS", trim=trim, bandwidth=bw)
@df grambank density!(:mean_distance, label="Grambank", trim=trim, bandwidth=bw)
title!("(A) Mean distance to neighbour")
p2 = @df wals density(:sd_distance, label="WALS", trim=trim, bandwidth=bw)
@df grambank density!(:sd_distance, label="Grambank", trim=trim, bandwidth=bw)
title!("(B) Standard deviation of distance to neighbour")

plot(p1, p2,
     layout=(2,1),
     titlefontsize=11,
     titlelocation=:left,
     top_margin=[0mm 0mm],
     size=(700,500),
     dpi=200)
xlabel!("kilometers")
xlims!(0, 2600)

savefig("../results/plots/distances.png")
