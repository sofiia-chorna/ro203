struct Cell
    x::Int64
    y::Int64
    mirror::Bool
end

function isOutOfBounds(cell::Cell, dimensions::Array{Int64})
    return cell.x < 1 || cell.x > dimensions[1] || cell.y < 1 || cell.y > dimensions[2]
end

function changeDirection(direction::String, mirrorType::Int64)
    directionChanges = Dict(
        "down" => Dict(4 => "left", 5 => "right"),
        "left" => Dict(4 => "down", 5 => "up"),
        "up" => Dict(4 => "right", 5 => "left"),
        "right" => Dict(4 => "up", 5 => "down")
    )
    return directionChanges[direction][mirrorType]
end

function moveNextCell(direction::String, cell::Cell)
    coordinateChanges = Dict(
        "down" => (1, 0),
        "left" => (0, -1),
        "up" => (-1, 0),
        "right" => (0, 1)
    )
    dx, dy = coordinateChanges[direction]
    return Cell(cell.x + dx, cell.y + dy, cell.mirror)
end

function createPath(dimensions::Array{Int64}, grid::Matrix{Int64})
    rows, cols = dimensions

    # Initialize an array to store all paths
    paths = Vector{Vector{Vector{Int64}}}() 

    # Iterate over each possible starting point for the light beam
    for i in 1:(2 * (rows + cols))
        path = Vector{Vector{Int64}}()
        
        # Determine the starting position and direction based on the current iteration
        if i <= cols
            direction = "down"
            x, y = 1, i
        elseif i <= rows + cols
            direction = "left"
            x, y = i - cols, cols
        elseif i <= 2 * cols + rows
            direction = "up"
            x, y = rows, 2 * cols + rows + 1 - i
        else
            direction = "right"
            x, y = 2 * cols + 2 * rows + 1 - i, 1
        end

        mirror = true

        # Continue moving the light until it goes out of bounds
        while !isOutOfBounds(Cell(x, y, false), dimensions)
            # If there is a mirror
            if grid[x, y] in (4, 5)
                mirror = false

                # Change direction accordingly
                direction = changeDirection(direction, grid[x, y])
            else
                # Add the current cell to the path
                push!(path, [x, y, mirror])
            end

            # Move to the next cell
            x, y = moveNextCell(direction, Cell(x, y, false)).x, moveNextCell(direction, Cell(x, y, false)).y
        end

        # Add the path to the list of paths
        push!(paths, path)
    end
    return paths
end
