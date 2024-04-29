# This file contains functions related to reading, writing and displaying a grid and experimental results

using JuMP
using Plots
import GR

include("instance.jl")
include("path.jl")

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
    gridLayout = zeros(Int, rows, columns)
    for i in 1:rows
        line = data[i + 4]
        if length(line) != columns
            println("Problem with grid layout in input file")
        end
        for j in 1:columns
            if line[j] == '/'
                gridLayout[i, j] = 4
            elseif line[j] == '\\'
                gridLayout[i, j] = 5
            end
        end
    end

    # Parse path values
    pathValues = map(x -> parse(Int64, x), split(data[rows + 5], ','))
    if length(pathValues) != 2 * (rows + columns)
        println("Problem in the input file: wrong number of values for path")
    end

    # Create paths of light in the grid
    paths = createPath(dimensions, gridLayout)

    return UndeadProblem(dimensions, gridLayout, totalZombies, totalGhosts, totalVampires, paths, pathValues)
end

function displayGrid(instance::UndeadProblem)
    println("--------Undead : Grid--------")
    println("Ghosts : ", instance.totalGhosts)
    println("Vampires : ", instance.totalVampires)
    println("Zombies : ", instance.totalZombies)
    println("")

    N = instance.dimensions
    X = instance.grid
    Y = instance.visibleMonsters

    # Print values of paths beginning on the top
    print(" ")
    for i in 1:N[2]
        print(" ", Y[i])
    end

    println("")

    for i in 1:N[1]
        indice = 2 * (N[1] + N[2]) - i + 1

        # Print value of path beginning on the left
        print(Y[indice])

        # Print line of grid
        for j in 1:N[2]
            print(" ")
            if X[i, j] == 4
                print("/")
            elseif X[i, j] == 5
                print("\\")
            else
                print(" ")
            end
        end

        print(" ")

        # Print value of path beginning on the right
        println(Y[N[2] + i])
    end

    # Print values of paths beginning from the bottom
    print(" ")
    for i in 1:N[2]
        print(" ")
        ind = N[1] + 2 * N[2] - i + 1
        print(Y[ind])
    end
    println("")
end

function displaySolution(instance, log = stdout)
    println("--------Undead : Solution--------")
    println("Ghosts : ", instance.totalGhosts)
    println("Vampires : ", instance.totalVampires)
    println("Zombies : ", instance.totalZombies)
    println("")

    N = instance.dimensions
    X = instance.grid
    Y = instance.visibleMonsters

    # Print values of paths beginning on the top
    print(log, " ")
    for i in 1:N[2]
        print(log, " ")
        print(log, Y[i])
    end
    println(log, "")
    for i in 1:N[1]
        indice = 2 * (N[1] + N[2]) - i + 1

        # Print value of path beginning on the left
        print(log, Y[indice])

        # Print line of grid
        for j in 1:N[2]
            print(log, " ")
            if X[i,j] == 1
                print(log, "G")
            elseif X[i,j] == 2
                print(log, "Z")
            elseif X[i,j] == 3
                print(log, "V")
            elseif X[i,j] == 4
                print(log, "/")
            elseif X[i,j] == 5
                print(log, "\\")
            else
                print(log, " ")
            end
        end

        # Print value of path beginning on the right
        print(log, " ")
        println(log, Y[N[2] + i])
    end

    # Print values of paths beginning from the bottom
    print(log, " ")
    for i in 1:N[2]
        print(log, " ")
        ind = N[1] + 2 * N[2] - i + 1
        print(log, Y[ind])
    end
    println(log, "")
end

function writeToFile(isSolution::Bool, prob::UndeadProblem, file::IOStream)
    # Write dimensions
    write(file, "# Dimensions:")
    write(file, "\n")
    write(file, string(prob.dimensions[1]), ",", string(prob.dimensions[2]))
    write(file, "\n")

    # Write totals of monsters
    write(file, "# Totals of monsters:")
    write(file, "\n")
    write(file, "G=", string(prob.totalGhosts))
    write(file, "\n")
    write(file, "V=", string(prob.totalVampires))
    write(file, "\n")
    write(file, "Z=", string(prob.totalZombies))
    write(file, "\n")

    # Write grid layout
    write(file, "# Grid layout:")
    write(file, "\n")
    for i in 1:prob.dimensions[1]
        for j in 1:prob.dimensions[2]
            if prob.grid[i, j] == 0
                write(file, "-")
            elseif prob.grid[i, j] == 4
                write(file, "\\")
            elseif prob.grid[i, j] == 5
                write(file, "/")
            else
                if isSolution
                    if prob.grid[i, j] == 1
                        write(file, "G")
                    elseif prob.grid[i, j] == 2
                        write(file, "Z")
                    elseif prob.grid[i, j] == 3
                        write(file, "V")
                    end
                else
                    write(file, "-")
                end
            end
        end
        write(file, "\n")
    end

    # Write path
    write(file, "# Path")
    write(file, "\n")
    for val in prob.visibleMonsters[1:end-1]
        write(file, string(val), ",")
    end
    write(file, string(prob.visibleMonsters[end]), "\n")
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
