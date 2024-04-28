# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX, JuMP
using MathOptInterface

include("generation.jl")

TOL = 0.00001

GHOST = 1
VAMPIRE = 2
ZOMBIE = 3

function monsterType(k::Int)
    if k == GHOST
        return "G"  # Ghost
    elseif k == VAMPIRE
        return "V"  # Vampire
    else
        return "Z"  # Zombie
    end
end


function canBeSeen(monsterType::Int, isReflected::Bool)
    # Vampire is visible unless reflected
    isVampireVisible = monsterType != VAMPIRE || !isReflected

    # Ghost is visible only if reflected
    isGhostVisible = monsterType != GHOST || isReflected

    # Zombie is visible always
    isZombie = monsterType == ZOMBIE

    # Get the visibility of the monster
    return isVampireVisible || isGhostVisible || isZombie
end


"""
Solve a sudoku grid with CPLEX

Argument
- t: array of size n*n with values in [0, n] (0 if the cell is empty)

Return
- status: :Optimal if the problem is solved optimally
- x: 3-dimensional variables array such that x[i, j, k] = 1 if cell (i, j) has value k
- getsolvetime(m): resolution time in seconds
"""
function cplexSolve(tuple::Tuple{Matrix{String}, Vector{Int64}})
    t, creatures = tuple
    n = size(t, 1) - 2 # substract two as it is the contraints values
    println(n)

    # Extract number of each creature
    ghostNb, vampireNb, zombieNb = creatures

    # Create the model
    m = Model(CPLEX.Optimizer)

    @variable(m, x[1:n, 1:n, 1:n], Bin)

    # Each cell (i, j) has one value type of monsters
    @constraint(m, [i in 1:n, j in 1:n], sum(x[i, j, k] for k in 1:3) == 1)

    # Creatures number limitation
    @constraint(m, sum(x[i, j, GHOST] for i in 1:n, j in 1:n) == ghostNb)
    @constraint(m, sum(x[i, j, VAMPIRE] for i in 1:n, j in 1:n) == vampireNb)
    @constraint(m, sum(x[i, j, ZOMBIE] for i in 1:n, j in 1:n) == zombieNb)

    # Visibility limitation
    # for i in 1:n, j in 1:n
    #     visibleMonsters = 0
    
    #     # Iterate over row/column elements
    #     for k in 1:n
    #         # Check visibility based on the type of monster and presence of mirrors
    #         if canBeSeen(t[i, k], mirrorPresent)
    #             visibleMonsters += 1
    #         end
    #     end
    
    #     # Constraint to enforce visibility
    #     @constraint(m, visibleMonsters == clue_value)
    # end

    # Start a chronometer
    start = time()

    # Solve the model
    optimize!(m)

    # Extract the solution
    solution = Array{String}(undef, n, n)
    for i in 1:n, j in 1:n
        for k in 1:3
            if value(x[i, j, k]) > 0.5
                solution[i, j] = monsterType(k)
                break
            end
        end
    end

    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
    return primal_status(m) == MOI.FEASIBLE_POINT, x, time() - start
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
# function solveDataSet()

#     dataFolder = "../data/"
#     resFolder = "../res/"

#     # Array which contains the name of the resolution methods
#     resolutionMethod = ["cplex"]
#     #resolutionMethod = ["cplex", "heuristique"]

#     # Array which contains the result folder of each resolution method
#     resolutionFolder = resFolder .* resolutionMethod

#     # Create each result folder if it does not exist
#     for folder in resolutionFolder
#         if !isdir(folder)
#             mkdir(folder)
#         end
#     end
            
#     global isOptimal = false
#     global solveTime = -1

#     # For each instance
#     # (for each file in folder dataFolder which ends by ".txt")
#     for file in filter(x->occursin(".txt", x), readdir(dataFolder))  
        
#         println("-- Resolution of ", file)
#         readInputFile(dataFolder * file)

#         # TODO
#         println("In file resolution.jl, in method solveDataSet(), TODO: read value returned by readInputFile()")
        
#         # For each resolution method
#         for methodId in 1:size(resolutionMethod, 1)
            
#             outputFile = resolutionFolder[methodId] * "/" * file

#             # If the instance has not already been solved by this method
#             if !isfile(outputFile)
                
#                 fout = open(outputFile, "w")  

#                 resolutionTime = -1
#                 isOptimal = false
                
#                 # If the method is cplex
#                 if resolutionMethod[methodId] == "cplex"
                    
#                     # TODO 
#                     println("In file resolution.jl, in method solveDataSet(), TODO: fix cplexSolve() arguments and returned values")
                    
#                     # Solve it and get the results
#                     isOptimal, resolutionTime = cplexSolve()
                    
#                     # If a solution is found, write it
#                     if isOptimal
#                         # TODO
#                         println("In file resolution.jl, in method solveDataSet(), TODO: write cplex solution in fout") 
#                     end

#                 # If the method is one of the heuristics
#                 else
                    
#                     isSolved = false

#                     # Start a chronometer 
#                     startingTime = time()
                    
#                     # While the grid is not solved and less than 100 seconds are elapsed
#                     while !isOptimal && resolutionTime < 100
                        
#                         # TODO 
#                         println("In file resolution.jl, in method solveDataSet(), TODO: fix heuristicSolve() arguments and returned values")
                        
#                         # Solve it and get the results
#                         isOptimal, resolutionTime = heuristicSolve()

#                         # Stop the chronometer
#                         resolutionTime = time() - startingTime
                        
#                     end

#                     # Write the solution (if any)
#                     if isOptimal

#                         # TODO
#                         println("In file resolution.jl, in method solveDataSet(), TODO: write the heuristic solution in fout")
                        
#                     end 
#                 end

#                 println(fout, "solveTime = ", resolutionTime) 
#                 println(fout, "isOptimal = ", isOptimal)
                
#                 # TODO
#                 println("In file resolution.jl, in method solveDataSet(), TODO: write the solution in fout") 
#                 close(fout)
#             end


#             # Display the results obtained with the method on the current instance
#             include(outputFile)
#             println(resolutionMethod[methodId], " optimal: ", isOptimal)
#             println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
#         end         
#     end 
# end
