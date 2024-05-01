# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX, JuMP
using MathOptInterface

include("generation.jl")
include("constants.jl")

TOL = 0.00001

"""
Solve a sudoku grid with CPLEX

Argument
- t: array of size n*n with values in [0, n] (0 if the cell is empty)

Return
- status: :Optimal if the problem is solved optimally
- x: 3-dimensional variables array such that x[i, j, k] = 1 if cell (i, j) has value k
- getsolvetime(m): resolution time in seconds
"""
function cplexSolve(inst::UndeadProblem)
    rows, cols = inst.dimensions
    Z = inst.totalZombies
    G = inst.totalGhosts
    V = inst.totalVampires
    C = inst.paths
    Y = inst.visibleMonsters

    # Create the model
    m = Model(CPLEX.Optimizer)

    # Declare the variable
    @variable(m, x[1:rows, 1:cols, 1:5], Bin)

    # Declare the constraints
    ## Constraint on mirrors place on the grid
    for i in 1:rows
        for j in 1:cols
            if inst.grid[i,j] == SLASH || inst.grid[i,j] == BACKSLASH
                @constraint(m, x[i,j,inst.grid[i,j]] == 1)
            end
        end
    end

    # Constraint on unicity of the type of box
    @constraint(m, [i = 1:rows, j = 1:cols], sum(x[i,j,k] for k in 1:5) == 1)

    # Constraint on number of monsters per type
    @constraint(m, sum(x[i,j, 1] for i = 1:rows, j = 1:cols) == G)
    @constraint(m, sum(x[i,j, 2] for i = 1:rows, j = 1:cols) == Z)
    @constraint(m, sum(x[i,j, 3] for i = 1:rows, j = 1:cols) == V)

    # Constraint on number of monsters on each path
    for c in 1:size(C, 1)
        zombies = sum(x[C[c][el][1], C[c][el][2], ZOMBIE] for el in 1:size(C[c], 1))
        vampires = sum(x[C[c][el][1], C[c][el][2], VAMPIRE] * C[c][el][3] for el in 1:size(C[c], 1))
        ghosts = sum(x[C[c][el][1], C[c][el][2], GHOST] * (1 - C[c][el][3]) for el in 1:size(C[c], 1))
        @constraint(m, zombies + vampires + ghosts == Y[c])
    end
    
    # Start a chronometer
    start = time()
    
    # Solve the model
    optimize!(m)

    # Check if the model has a feasible solution
    if primal_status(m) == MOI.FEASIBLE_POINT
        buf = JuMP.value.(x)
        for i in 1:size(buf, 1)
            for j in 1:size(buf, 2)
                for k in 1:size(buf, 3)
                    if buf[i,j,k] == 1
                        inst.grid[i,j] = k
                    end
                end
            end
        end
        return true, x, time() - start
    else
        println("No feasible solution found.")
        return false, nothing, time() - start
    end
end

"""
Heuristically solve an instance
"""
function heuristicSolve()

    # TODO
    println("In file resolution.jl, in method heuristicSolve(), TODO: fix input and output, define the model")
    
end 

"""
Solve all the instances contained in "../data" through CPLEX and heuristics

The results are written in "../res/cplex" and "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""
function solveDataSet(log = stdout)
    dataFolder = "../data/"
    resFolder = "../res/"
    resInstFolder = "../resInst/"

    # Array which contains the name of the resolution methods
    resolutionMethod = ["cplex"]
    resolutionFolder = resFolder .* resolutionMethod

    for folder in resolutionFolder
        if !isdir(folder)
            mkdir(folder)
        end
    end

    global isOptimal = false
    global solveTime = -1

    # For each instance
    # (for each file in folder dataFolder which ends by ".txt")
    for file in filter(x->occursin(".txt", x), readdir(dataFolder))
        println("-- Resolution of ", file)
        t = readInputFile(dataFolder * file)

        # For each resolution method
        for methodId in 1:size(resolutionMethod, 1)
            outputFile = resolutionFolder[methodId] * "/" * file

            # If the instance has not already been solved by this method
            if !isfile(outputFile)
                fout = open(outputFile, "w")
                resolutionTime = -1
                isOptimal = false

                # If the method is cplex
                if resolutionMethod[methodId] == "cplex"
                    # Solve it and get the results
                    isOptimal, x, resolutionTime = cplexSolve(t)

                    # If a solution is found, write it
                    if isOptimal
                        writeToFile(true, t, fout)
                    end
                end

                println(fout, "solveTime = ", resolutionTime)
                println(fout, "isOptimal = ", isOptimal)
                close(fout)
            end
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits = 2)) * "s\n")
        end
    end
end
