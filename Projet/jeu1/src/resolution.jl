# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX, JuMP
using MathOptInterface

include("generation.jl")

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
    # Extract instance attributes
    N = inst.dimensions
    Z = inst.totalZombies
    G = inst.totalGhosts
    V = inst.totalVampires
    C = inst.paths
    visibleMonsters = inst.visibleMonsters

    # Create the model
    model = Model(CPLEX.Optimizer)

    # Declare the variable
    @variable(model, x[1:N[1], 1:N[2], 1:5], Bin)

    # Constraint on mirrors placed on the grid
    for i in 1:N[1]
        for j in 1:N[2]
            if inst.grid[i,j] == 4 || inst.grid[i,j] == 5
                @constraint(model, x[i,j,inst.grid[i,j]] == 1)
            end
        end
    end

    # Constraint on the uniqueness of the type of box
    @constraint(model, [i = 1:N[1], j = 1:N[2]], sum(x[i,j,k] for k in 1:5) == 1)
    
    # Constraint on the number of monsters per type
    @constraint(model, sum(x[i,j,1] for i = 1:N[1], j = 1:N[2]) == G)
    @constraint(model, sum(x[i,j,2] for i = 1:N[1], j = 1:N[2]) == Z)
    @constraint(model, sum(x[i,j,3] for i = 1:N[1], j = 1:N[2]) == V)

    # Constraint on the number of monsters per path
    for c in 1:size(C, 1)
        sumZombies = sum(x[C[c][el][1], C[c][el][2], 2] for el in 1:size(C[c], 1))
        sumVampires = sum(x[C[c][el][1], C[c][el][2], 3] * C[c][el][3] for el in 1:size(C[c], 1))
        sumGhosts = sum(x[C[c][el][1], C[c][el][2], 1] * (1 - C[c][el][3]) for el in 1:size(C[c], 1))
        @constraint(model, sumZombies + sumVampires + sumGhosts == visibleMonsters[c])
    end

    # Start a timer
    startTime = time()

    # Solve the model
    optimize!(model)
    
    # Update the grid layout with the solution
    solution = JuMP.value.(x)
    for i in 1:size(solution, 1)
        for j in 1:size(solution, 2)
            for k in 1:size(solution, 3)
                if solution[i,j,k] == 1
                    inst.grid[i,j] = k
                end
            end
        end
    end

    isFeasible = primal_status(model) == MOI.FEASIBLE_POINT
    elapsedTime = time() - startTime

    return isFeasible, x, elapsedTime
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
