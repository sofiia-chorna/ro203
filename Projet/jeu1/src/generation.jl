# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")
include("constants.jl")
using Random

"""
Generate an n*n grid of game

Argument
- N: size of the grid (tuple of 2 dimensions)
"""
function generateInstance(N::Array{Int64})
    rows, cols = N

    # Array that will contain the generated grid
    X = zeros(Int, rows, cols)

    # Counting the total number of monsters at the same time
    G = 0
    V = 0
    Z = 0
    for i in 1:rows
        for j in 1:cols
            # Choosing randomly the type of the cell (mirror, monster)
            mirror = rand()
            if mirror < 1 / 5 # probability of having a mirror
                if rand() < 1 / 2
                    X[i,j] = SLASH
                else
                    X[i,j] = BACKSLASH
                end
            else
                type = rand((GHOST, ZOMBIE, VAMPIRE))
                X[i,j] = type
                if type == GHOST
                    G += 1
                elseif type == ZOMBIE
                    Z += 1
                elseif type == VAMPIRE
                    V += 1
                end
            end
        end
    end
    C = createPath(N, X)

    # Array that contains the values of each path
    Y = zeros(Int, 2 * (rows + cols))
    for c in 1:2 * (rows + cols)
        path = C[c]
        for i in 1:size(path, 1)
            cell = path[i]
            # If it is a zombie, we will see it
            if X[cell[1],cell[2]] == 2
                Y[c] += 1

            # If it is a ghost and there is a reflection
            elseif X[cell[1],cell[2]] == 1 && cell[3] == 0
                Y[c] += 1

            # If it is a vampire and there is no reflection
            elseif X[cell[1],cell[2]] == 3 && cell[3] == 1
                Y[c] += 1
            end
        end
    end
    return UndeadProblem(N, X, Z, G, V, C, Y)
end

"""
Generate all the instances

Arguments :
- N : size of grid (tuple of 2 dimensions)
- nb_inst : nb of instances that will be generated

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet()
    # For each grid size considered
    for size in [4, 9, 16, 25]
        N = [size,size]
        # Generate 10 instances
        for instance in 1:10
            # Saving the instance to solve and its solution
            fileName = "../data/instance_n" * string(size) * "_" * string(instance) * ".txt"
            if !isfile(fileName)
                game = generateInstance(N)
                file = open(fileName, "w")
                println("-- Generating file " * fileName)
                writeToFile(false, game, file)
                close(file)
            end
        end
    end
end
