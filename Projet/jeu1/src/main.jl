include("io.jl")
include("resolution.jl")
include("generation.jl")

function main()
    # generateDataSet()
    # instance::UndeadProblem = readInputFile("../data/instanceTest2.txt")
    # instance::UndeadProblem = readInputFile("../data/instance_n4_2.txt")

    # displayGrid(instance)   
    # isFeasible, x, elapsedTime = cplexSolve(instance)
    # println("is feasible", isFeasible)
    # displaySolution(instance, x)
    solveDataSet();
end

main()
