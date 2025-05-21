# whether to include control features or not, and what the controls are
include_controls = true

# neighbourhood sizes 
#degrees = 100:50:4000  # km based
degrees = 1:1:500  # rank based
#degrees = 10:100:1500  # rank based

# features
features = vcat(first.(fPairs), construct)
features_pre_preprocessing = vcat(first.(fPairs), auxiliary)
fPairsc = fPairs

# if we want to include controls
if include_controls
    control_features = last.(control)
    features = vcat(features, control_features)
    features_pre_preprocessing = vcat(features_pre_preprocessing, first.(control))
    fPairsc = vcat(fPairs, control)
end

# this is used later to pretty-print stuff
fDict = Dict(fPairsc)

# as is this
features_pretty = copy(features)
[replace!(features_pretty, p) for p in fPairs]

# alpha level for deciding underattested/overattested
alpha = 0.05
