"""
    Struct representing an instance of an undead problem.

    Attributes:
    - dimensions: Tuple (rows, columns) of Int64 representing the dimensions of the instance
    - grid: Array{Int64, 2} representing the grid. Each cell can have:
        - 0: empty
        - 1: ghost
        - 2: zombie
        - 3: vampire
        - 4: mirror /
        - 5: mirror \\
    - totalZombies: Int64
    - totalGhosts: Int64
    - totalVampires: Int64
    - paths: Vector{Vector{Vector{Int64}}}, vectors of 2*(rows + columns) elements representing the path. Each element of the path has 3 items: the first two are coordinates and the third is equal to 1 if the cell is before a mirror, 0 otherwise
    - visibleMonsters: Array{Int64} of 2*(rows + columns) representing the number of visible monsters for each path
"""
struct UndeadProblem
    dimensions::Array{Int64}
    grid::Array{Int64, 2}
    totalZombies::Int64
    totalGhosts::Int64
    totalVampires::Int64
    paths::Vector{Vector{Vector{Int64}}}
    visibleMonsters::Array{Int64}
end

function UndeadProblem(instance::UndeadProblem)
    N = copy(instance.dimensions)
    X = copy(instance.grid)
    Z = instance.totalZombies
    G = instance.totalGhosts
    V = instance.totalVampires
    C = copy(instance.paths)
    Y = copy(instance.visibleMonsters)
    return UndeadProblem(N, X, Z, G, V, C, Y)
end