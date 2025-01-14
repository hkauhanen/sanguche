dataset = ARGS[1]

all_fams = open("../../$dataset/data/glot3.txt", "r") do file
  readlines(file)
end

large_fams = open("fm_large_$dataset.txt", "r") do file
  readlines(file)
end

prob_fams = open("fm_problematic_$dataset.txt", "r") do file
  readlines(file)
end

normal_fams = all_fams[all_fams .∉ [vcat(large_fams, prob_fams)]]
reverse!(normal_fams)

open("fm_rest_$dataset.txt", "w") do file
  [println(file, fm) for fm in normal_fams]
end
