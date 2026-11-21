include("deps.jl")

using Distributed


@everywhere using Pkg
@everywhere Pkg.activate("Sanguche")
#@everywhere Pkg.instantiate()

@everywhere using ProgressMeter


try
    mkdir("../longresults")
catch e
end


# all processors need access to the following
@everywhere using CSV
@everywhere using DataFrames
@everywhere using FreqTables
@everywhere using Random
@everywhere using Serialization
@everywhere using Statistics
@everywhere using Pipe


# for a mysterious reason, we need to do the following to pass the 
# command-line argument to all worker processes; cf.
# https://discourse.julialang.org/t/how-to-pass-args-to-multiple-processes/80075/3
@everywhere myargfunc(x) = x
@everywhere dataset = myargfunc($ARGS)[1]
#@everywhere limtype = myargfunc($ARGS)[2]


@everywhere grid = deserialize("../tmp/$dataset/dicts/grid.jls")
@everywhere Ddata = deserialize("../tmp/$dataset/dicts/Ddata.jls")
@everywhere Ddists = deserialize("../tmp/$dataset/dicts/Ddists.jls")


#@everywhere grid = grid[!, Not(:degree)] |> unique
@everywhere grid = grid |> unique


@everywhere jawa = CSV.read("../tmp/gbwals_all_pairs.csv", DataFrame)

@everywhere subset!(jawa, :dataset => (ds -> lowercase.(ds) .== dataset))

@everywhere transform!(jawa, [:feat1, :feat2] => ByRow(((a,b) -> "$a-$b")) => :fpair)
@everywhere transform!(jawa, :fpair => (fp -> Set.(split.(fp, "-"))) => :pair_ID)

@everywhere transform!(grid, :pair => (p -> Set.(split.(p, " & "))) => :pair_ID)


@everywhere LBFLEVEL = 4.0


@everywhere grid = outerjoin(grid, jawa, on = :pair_ID)

# assume control pairs are non-interacting by fiat
@everywhere grid.lbf = ifelse.(ismissing.(grid.lbf), -100.0, grid.lbf)

@everywhere grid.status = ifelse.(grid.lbf .>= LBFLEVEL, "interacting", "non-interacting")


# get join counts for feature pair 'pair'
@everywhere function joincounts(pair;
        degree = 100,
        gravity_exponent = 1.0,
        gravity_type = "km")
    data = deepcopy(Ddata[pair])
    dist = Ddists[pair]

    dist.distance .= ifelse.(dist.distance .== 0, 10, dist.distance)

    gridhere = subset(grid, :pair => (p -> p .== pair))

    data.pair .= pair
    data.degree .= degree
    data.gravity_exponent .= gravity_exponent
    data.gravity_type .= gravity_type

    data.frequency .= -1.0
    data.class .= ""
    data.attestation .= ""
    data.status .= gridhere.status

    data.pedigree .= ""

    data.joincount .= -1.0

    data.min_distance .= -1.0
    data.mean_distance .= -1.0
    data.max_distance .= -1.0

    for r in eachrow(data)
        lang = r.Language_ID
        focal = r.type

        f1 = focal[1]
        f2 = focal[2]

        f1joins = f1 .* ["1", "2"]
        f2joins = ["1", "2"] .* f2
        ORjoins = union(f1joins, f2joins)

        distances = subset(dist, :language_ID => (lid -> lid .== lang))

        subset!(distances, :eachindex => (id -> id .<= degree))

        neighbours = distances.neighbour_ID

        neighbours_data = subset(data, :Language_ID => (lid -> lid .∈ [neighbours]))

        neighbours_of_relevant_type = subset(neighbours_data, :type => (typ -> typ .∈ [ORjoins])).Language_ID

        # distances to relevant_neighbours
        drn = subset(distances, :neighbour_ID => (nid -> nid .∈ [neighbours_of_relevant_type]))

        if nrow(drn) > 0
            r.min_distance = minimum(drn.distance)
            r.mean_distance = Statistics.mean(drn.distance)
            r.max_distance = maximum(drn.distance)

            if gravity_type == "km"
                joincount = sum(drn.distance .^ -gravity_exponent)
            elseif gravity_type == "rank"
                joincount = sum(drn.eachindex .^ -gravity_exponent)
            end

            r.joincount = joincount
        else
            r.min_distance = NaN
            r.mean_distance = NaN
            r.max_distance = NaN
            r.joincount = NaN
        end

        r.frequency = gridhere[!, "freq" * focal][1]
        r.class = gridhere.class[1]

        if gridhere[!, "pref" * focal][1] == 1
            r.attestation = "overattested"
        elseif gridhere[!, "dispref" * focal][1] == 1
            r.attestation = "underattested"
        else
            r.attestation = "NA"
        end

        if r.status == "interacting" && r.attestation == "underattested"
            r.pedigree = "dispreferred"
        elseif r.class == "control" && r.attestation == "underattested"
            r.pedigree = "control under"
        elseif r.status == "interacting" && r.attestation == "overattested"
            r.pedigree = "preferred"
        elseif r.class == "control" && r.attestation == "overattested"
            r.pedigree = "control over"
        else
            r.pedigree = "other"
        end
    end

    transform!(data, :pair => (p -> Tuple.(split.(p, " & "))) => [:f1, :f2])
    data.ptype .= data.f1 .* data.f2 .* data.type

    return data[:, [:pair, :class, :status, :type, :ptype, :attestation, :pedigree, :Language_ID, :Family, :degree, :gravity_exponent, :gravity_type, :min_distance, :mean_distance, :max_distance, :frequency, :joincount]]
end


@everywhere resultgrid = allcombinations(pair = unique(grid.pair),
                                         degree = [10, 20, 50, 100],
                                         gravity_exponent = [0.0, 0.1, 0.25, 0.5, 1.0, 2.0],
                                         gravity_type = ["km", "rank"],
                                         DataFrame)

results = @showprogress dt=1 desc="Computing..." @distributed (vcat) for r in eachrow(resultgrid)
    joincounts(r.pair; degree = r.degree, gravity_exponent = r.gravity_exponent, gravity_type = r.gravity_type)
end


CSV.write("../longresults/newjoins_$dataset.csv", results)
