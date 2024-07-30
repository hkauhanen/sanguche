using DataFrames
using Serialization
using Statistics

#dataset = ARGS[1]
#max_degree = parse(Int, ARGS[2])
dataset = "grambank"
max_degree = 20

Ddists = deserialize("../tmp/$dataset/Ddists.jls")

truly_alldata = DataFrame()

# loop through all possible degrees
for degree in 1:max_degree
# put all distance data into a single dataframe; use split-apply-combine
# to get mean distance per language
alldata = DataFrame()
for key in keys(Ddists)
	result = combine(groupby(subset(Ddists[key], :eachindex => i -> i .<= degree), :language_ID), :distance => std)
	result.pair .= key
	alldata = [alldata; result]
end

# get standard deviation of mean distances for each pair
alldata = combine(groupby(alldata, :pair), :distance_std => std)

alldata.degree .= degree

global truly_alldata = [truly_alldata; alldata]
end

truly_alldata

#res = [mean(subset(data, :eachindex => i -> i .<= degree).distance) for data in values(Ddists), degree in 1:max_degree]
#
#res2 = mapcols(col -> std(col), DataFrame(res, :auto))
