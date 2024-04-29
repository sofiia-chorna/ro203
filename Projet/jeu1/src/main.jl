include("io.jl")
include("resolution.jl")

function extract_solution(x::Array{VariableRef, 3})
    N = size(x)
    solution = fill(0, N[1], N[2])
    for i in 1:N[1]
        for j in 1:N[2]
            for k in 1:N[3]
                if value(x[i,j,k]) == 1
                    solution[i,j] = k
                end
            end
        end
    end
    return solution
end

function main()
    instance::UndeadProblem = readInputFile("../data/instanceTest2.txt")
    displayGrid(instance)   
    # Call cplexSolve to solve the problem
    isFeasible, x, elapsedTime = cplexSolve(instance)

    # Check if the problem is feasible and the solution is obtained
    # if isFeasible
    #     println("Solution found in $elapsedTime seconds.")
        
    #     # Extract the solution from the variable x
    #     # solution = extract_solution(x)
        
    #     # Display the solution using displaySolution function
    displaySolution(instance, x)
    # else
    #     println("No feasible solution found.")
    # end
end

main()
