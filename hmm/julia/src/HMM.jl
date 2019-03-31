module HMM

import Random
using StatsBase

export TAGS
export StemCount, stemtrain, predict
export evaluate

# Instance is a list of word attributes as kept in MLDatasets
Instance = Array{Array{String,1},1}

# Prediction is a list of tag, one for each word
Prediction = Array{String,1}

const TAGS = [
    "DET",
    "PROPN",
    "PUNCT",
    "ADJ",
    "SCONJ",
    "NOUN",
    "NUM",
    "X",
    "VERB",
    "ADV",
    "AUX",
    "PRON",
    "PART",
    "CCONJ",
    "ADP",
    "SYM",
    "INTJ"
]

"""
A random tag prediction that gives around 94% error
"""
function predict(x::Instance)::Prediction
    map(_ -> TAGS[Random.rand(1:end)], x)
end

"""
Plain unigram-ish count gives 18% error
"""
struct StemCount
    counts::Dict{String, Dict{String, Float64}}
end

function stemtrain(traindata::Array{Instance,1})::StemCount
    counts = Dict()
    stemindex = 3
    tagindex = 4

    for x in traindata
        for word in x
            stem = word[stemindex]
            tag = word[tagindex]

            if !(stem in keys(counts))
                counts[stem] = Dict()
            end

            counts[stem][tag] = get(counts[stem], tag, 0) + 1
        end
    end

    for stem in keys(counts)
        normalize!(counts[stem])
    end

    StemCount(counts)
end

function predict(model::StemCount, x::Instance)::Prediction
    output = []
    stemindex = 3

    for i in 1:length(x)
        conditionals = get(model.counts, x[i][stemindex], Dict())
        weights = ProbabilityWeights(map(t -> get(conditionals, t, 0), TAGS))

        push!(output, sample(TAGS, weights))
    end

    output
end

struct HMModel
    n::Int # Number of states
    m::Int # Number of observation states

    transition::Array{Float64,2}
    initial::Array{Float64,1}
    # TODO: Emissions should be something different
    emission::Array{Float64,2}
end

"""
Tell likelihood of observed values (words here). This is the
problem 1 from rabiner.
"""
function likelihood(model::HMModel, x::Instance)::Float64
    obindex = 3 # Choosing stem as the observation
    observations = [w[obindex] for w in x]

    # TODO: We need to go from observation to a certain index
    o2i(o) = 1

    # Converting to row vector for convenience
    statedist = model.initial'

    totalprob = 0
    for o in observations
        totalprob += sum(statedist .* emmission[:, o2i(o)])
        statedist = statedist * transition
    end

    totalprob
end

"""
Problem 3 from rabiner
"""
function hmmtrain(traindata::Array{Instance,1})::HMModel
    # TODO
end

"""
Problem 2 from rabiner. NOTE: Only when the observed sequence is words
and hidden states are tags.
"""
function predict(model::HMModel, x::Instance)::Prediction
    # TODO Viterbi, also should understand when anyone throws 'viterbi' as
    #      a general term around
end

"""
Basic error count evaluator for universal tag prediction. We assume data
from MLDatasets and model from providing array of tags for each sentence.

Also note that this is not the right way to evaluate so we will be careful
when drawing conclusions.
"""
function evaluate(predictions::Array{Prediction,1}, testdata)::Float64
    @assert length(predictions) == length(testdata)

    errors = 0
    tagindex = 4

    for (truth, pred) in zip(testdata, predictions)
        for (tfields, ptag) in zip(truth, pred)
            if ptag != tfields[tagindex]
                errors += 1
            end
        end
    end

    errors / sum(map(length, testdata))
end

end