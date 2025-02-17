# This file contains functions related to reading, writing and displaying a grid and experimental results

using JuMP
using Plots
import GR

include("instance.jl")
include("path.jl")
include("constants.jl")


function parseValue(value, allowUnknown=false)
    if value == HYPHEN
        return "-"
    elseif value == GHOST
        return "G"
    elseif value == ZOMBIE
        return "Z"
    elseif value == VAMPIRE
        return "V"
    elseif value == BACKSLASH
        return "\\"
    elseif value == SLASH
        return "/"
    elseif allowUnknown
        return " "
    else
        print("Unknown value : ", value, "!")
    end
end

"""
Read an instance from an input file

- Argument:
inputFile: path of the input file
"""
function readInputFile(inputFile::String)
    # Open the input file
    datafile = open(inputFile)
    data = readlines(datafile)
    close(datafile)

    # Filter out empty and comment lines
    data = filter(line -> !isempty(strip(line)) && line[1] != '#', data)

    # Extract grid dimensions
    dimensions = split(data[1], ',')
    rows = parse(Int, dimensions[1])
    columns = parse(Int, dimensions[2])
    dimensions = [rows, columns]

    # Parse number of monsters
    parseMonsters(line::String) = parse(Int, split(line, '=')[2])
    totalGhosts = parseMonsters(data[2])
    totalVampires = parseMonsters(data[3])
    totalZombies = parseMonsters(data[4])

    # Parse grid layout
    grid = zeros(Int, rows, columns)
    for i in 1:rows
        line = data[i + 4]
        if length(line) != columns
            println("Problem with grid layout in input file")
        end
        for j in 1:columns
            if line[j] == '/'
                grid[i, j] = SLASH
            elseif line[j] == '\\'
                grid[i, j] = BACKSLASH
            end
        end
    end

    # Parse path values
    pathValues = map(x -> parse(Int64, x), split(data[rows + 5], ','))
    if length(pathValues) != 2 * (rows + columns)
        println("Problem in the input file: wrong number of values for path")
    end

    # Create paths of light in the grid
    paths = createPath(dimensions, grid)

    # Return instance of the problem
    return UndeadProblem(dimensions, grid, totalZombies, totalGhosts, totalVampires, paths, pathValues)
end

function display(instance::UndeadProblem, title::String="", solution::Bool=false)
    println("-------- ", title, " --------")
    println("Ghosts : ", instance.totalGhosts)
    println("Vampires : ", instance.totalVampires)
    println("Zombies : ", instance.totalZombies)
    println("")

    rows, cols = instance.dimensions

    # Calculate the length of the line based on symbol width
    symbolWidth = 2
    lineLength = 2 * (4 + cols * symbolWidth)

    # Print values of paths beginning on the top
    print("   ")
    for i in 1:cols
        print(" ")
        print(rpad(instance.visibleMonsters[i], symbolWidth + 1))
    end

    println("")
    printLine(lineLength)

    for i in 1:rows
        # Calculate index
        index = 2 * (rows + cols) - i + 1

        # Print value of path beginning on the left
        print(rpad(instance.visibleMonsters[index], symbolWidth), "| ")

        # Print line of grid
        for j in 1:cols
            value = parseValue(instance.grid[i,j], true)
            print(rpad(value, symbolWidth + 2))
        end

        # Print value of path beginning on the right
        print("| ", lpad(instance.visibleMonsters[cols + i], symbolWidth - 1))
        println()
    end

    printLine(lineLength)

    # Print values of paths beginning from the bottom
    print("   ")
    for i in 1:cols
        print(" ")
        index = rows + 2 * cols - i + 1
        print(rpad(instance.visibleMonsters[index], symbolWidth + 1))
    end
    println("")
end

function printLine(size::Int)
    for i in 1:size
        print("-")
    end
    println("")
end

function displayGrid(instance::UndeadProblem)
    title = "Undead : Grid"
    display(instance, title, false)
end

function displaySolution(instance)
    title = "Undead : Solution"
    display(instance, title, true)
end

function writeToFile(isSolution::Bool, instance::UndeadProblem, file::IOStream)
    # Get dimensions
    rows, cols = instance.dimensions

    # Write dimensions
    write(file, "# Dimensions:", "\n")
    write(file, string(rows), ",", string(cols), "\n")

    # Write totals of monsters
    write(file, "# Totals of monsters:", "\n")

    # Define map to iterate in its values
    dict = Dict("G" => instance.totalGhosts, "V" => instance.totalVampires, "Z" => instance.totalZombies)

    # Iterate over the pairs and write them to file
    for (key, value) in dict
        write(file, key, "=", string(value))
        write(file, "\n")
    end

    # Write grid layout
    write(file, "# Grid layout:")
    write(file, "\n")
    for i in 1:rows
        for j in 1:cols
            # Get current cell
            cell = instance.grid[i, j]

            # Write to the file parsed value
            write(file, parseValue(cell))
        end
        write(file, "\n")
    end

    # Write path
    write(file, "# Path", "\n")
    for v in instance.visibleMonsters[1:end-1]
        write(file, string(v), ",")
    end
    write(file, string(instance.visibleMonsters[end]), "\n")
end


"""
Create a pdf file which contains a performance diagram associated to the results of the ../res folder
Display one curve for each subfolder of the ../res folder.

Arguments
- outputFile: path of the output file

Prerequisites:
- Each subfolder must contain text files
- Each text file correspond to the resolution of one instance
- Each text file contains a variable "solveTime" and a variable "isOptimal"
"""
function performanceDiagram(outputFile::String)

    resultFolder = "../res/"
    
    # Maximal number of files in a subfolder
    maxSize = 0

    # Number of subfolders
    subfolderCount = 0

    folderName = Array{String, 1}()

    # For each file in the result folder
    for file in readdir(resultFolder)

        path = resultFolder * file
        
        # If it is a subfolder
        if isdir(path)
            
            folderName = vcat(folderName, file)
             
            subfolderCount += 1
            folderSize = size(readdir(path), 1)

            if maxSize < folderSize
                maxSize = folderSize
            end
        end
    end

    # Array that will contain the resolution times (one line for each subfolder)
    results = Array{Float64}(undef, subfolderCount, maxSize)

    for i in 1:subfolderCount
        for j in 1:maxSize
            results[i, j] = Inf
        end
    end

    folderCount = 0
    maxSolveTime = 0

    # For each subfolder
    for file in readdir(resultFolder)
            
        path = resultFolder * file
        
        if isdir(path)

            folderCount += 1
            fileCount = 0

            # For each text file in the subfolder
            for resultFile in filter(x->occursin(".txt", x), readdir(path))

                fileCount += 1
                include(path * "/" * resultFile)

                if isOptimal
                    results[folderCount, fileCount] = solveTime

                    if solveTime > maxSolveTime
                        maxSolveTime = solveTime
                    end 
                end 
            end 
        end
    end 

    # Sort each row increasingly
    results = sort(results, dims=2)

    println("Max solve time: ", maxSolveTime)

    # For each line to plot
    for dim in 1: size(results, 1)

        x = Array{Float64, 1}()
        y = Array{Float64, 1}()

        # x coordinate of the previous inflexion point
        previousX = 0
        previousY = 0

        append!(x, previousX)
        append!(y, previousY)
            
        # Current position in the line
        currentId = 1

        # While the end of the line is not reached 
        while currentId != size(results, 2) && results[dim, currentId] != Inf

            # Number of elements which have the value previousX
            identicalValues = 1

             # While the value is the same
            while results[dim, currentId] == previousX && currentId <= size(results, 2)
                currentId += 1
                identicalValues += 1
            end

            # Add the proper points
            append!(x, previousX)
            append!(y, currentId - 1)

            if results[dim, currentId] != Inf
                append!(x, results[dim, currentId])
                append!(y, currentId - 1)
            end
            
            previousX = results[dim, currentId]
            previousY = currentId - 1
            
        end

        append!(x, maxSolveTime)
        append!(y, currentId - 1)

        # If it is the first subfolder
        if dim == 1

            # Draw a new plot
            plot(x, y, label = folderName[dim], legend = :bottomright, xaxis = "Time (s)", yaxis = "Solved instances",linewidth=3)

        # Otherwise 
        else
            # Add the new curve to the created plot
            savefig(plot!(x, y, label = folderName[dim], linewidth=3), outputFile)
        end 
    end
end 

"""
Create a latex file which contains an array with the results of the ../res folder.
Each subfolder of the ../res folder contains the results of a resolution method.

Arguments
- outputFile: path of the output file

Prerequisites:
- Each subfolder must contain text files
- Each text file correspond to the resolution of one instance
- Each text file contains a variable "solveTime" and a variable "isOptimal"
"""
function resultsArray(outputFile::String)
    
    resultFolder = "../res/"
    dataFolder = "../data/"
    
    # Maximal number of files in a subfolder
    maxSize = 0

    # Number of subfolders
    subfolderCount = 0

    # Open the latex output file
    fout = open(outputFile, "w")

    # Print the latex file output
    println(fout, raw"""\documentclass{article}

\usepackage[french]{babel}
\usepackage [utf8] {inputenc} % utf-8 / latin1 
\usepackage{multicol}

\setlength{\hoffset}{-18pt}
\setlength{\oddsidemargin}{0pt} % Marge gauche sur pages impaires
\setlength{\evensidemargin}{9pt} % Marge gauche sur pages paires
\setlength{\marginparwidth}{54pt} % Largeur de note dans la marge
\setlength{\textwidth}{481pt} % Largeur de la zone de texte (17cm)
\setlength{\voffset}{-18pt} % Bon pour DOS
\setlength{\marginparsep}{7pt} % Séparation de la marge
\setlength{\topmargin}{0pt} % Pas de marge en haut
\setlength{\headheight}{13pt} % Haut de page
\setlength{\headsep}{10pt} % Entre le haut de page et le texte
\setlength{\footskip}{27pt} % Bas de page + séparation
\setlength{\textheight}{668pt} % Hauteur de la zone de texte (25cm)

\begin{document}""")

    header = raw"""
\begin{center}
\renewcommand{\arraystretch}{1.4} 
 \begin{tabular}{l"""

    # Name of the subfolder of the result folder (i.e, the resolution methods used)
    folderName = Array{String, 1}()

    # List of all the instances solved by at least one resolution method
    solvedInstances = Array{String, 1}()

    # For each file in the result folder
    for file in readdir(resultFolder)

        path = resultFolder * file
        
        # If it is a subfolder
        if isdir(path)

            # Add its name to the folder list
            folderName = vcat(folderName, file)
             
            subfolderCount += 1
            folderSize = size(readdir(path), 1)

            # Add all its files in the solvedInstances array
            for file2 in filter(x->occursin(".txt", x), readdir(path))
                solvedInstances = vcat(solvedInstances, file2)
            end 

            if maxSize < folderSize
                maxSize = folderSize
            end
        end
    end

    # Only keep one string for each instance solved
    unique(solvedInstances)

    # For each resolution method, add two columns in the array
    for folder in folderName
        header *= "rr"
    end

    header *= "}\n\t\\hline\n"

    # Create the header line which contains the methods name
    for folder in folderName
        header *= " & \\multicolumn{2}{c}{\\textbf{" * folder * "}}"
    end

    header *= "\\\\\n\\textbf{Instance} "

    # Create the second header line with the content of the result columns
    for folder in folderName
        header *= " & \\textbf{Temps (s)} & \\textbf{Optimal ?} "
    end

    header *= "\\\\\\hline\n"

    footer = raw"""\hline\end{tabular}
\end{center}

"""
    println(fout, header)

    # On each page an array will contain at most maxInstancePerPage lines with results
    maxInstancePerPage = 30
    id = 1

    # For each solved files
    for solvedInstance in solvedInstances

        # If we do not start a new array on a new page
        if rem(id, maxInstancePerPage) == 0
            println(fout, footer, "\\newpage")
            println(fout, header)
        end 

        # Replace the potential underscores '_' in file names
        print(fout, replace(solvedInstance, "_" => "\\_"))

        # For each resolution method
        for method in folderName

            path = resultFolder * method * "/" * solvedInstance

            # If the instance has been solved by this method
            if isfile(path)

                include(path)

                println(fout, " & ", round(solveTime, digits=2), " & ")

                if isOptimal
                    println(fout, "\$\\times\$")
                end 
                
            # If the instance has not been solved by this method
            else
                println(fout, " & - & - ")
            end
        end

        println(fout, "\\\\")

        id += 1
    end

    # Print the end of the latex file
    println(fout, footer)

    println(fout, "\\end{document}")

    close(fout)
    
end 
