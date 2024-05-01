include("io.jl")
include("resolution.jl")
include("generation.jl")

function main()
    # generateDataSet()
    # instance::UndeadProblem = readInputFile("../data/instanceTest2.txt")
    instance::UndeadProblem = readInputFile("../data/instance_n25_10.txt")
    # displayGrid(instance)   
    # isFeasible, x, elapsedTime = cplexSolve(instance)
    displaySolution(instance)
    # solveDataSet();
end

main()
