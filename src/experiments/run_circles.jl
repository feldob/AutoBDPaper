using Pkg; Pkg.instantiate(); Pkg.activate(".")

using AutoBVA
using AutoBDPaper
using CSV # 6_stats.jl

# --- circle section ---

# constants
circle_center_x = 0
circle_center_y = 0

circle_center_x2 = 100
circle_center_y2 = 100

circle_center_x3 = -100 
circle_center_y3 = -100

radius_small = 10
radius_medium = 50
radius_large = 100
radius_default = 80   

function solid_circle_sut(x::Integer, y::Integer)

    distance = sqrt((x - circle_center_x)^2 + (y - circle_center_y)^2)

    if x == 0 && y == 0
        throw(DomainError("The point should not be at the origin (0, 0)"))
    elseif distance <= radius_default
        return "in"
    else
        return "out"
    end

end

function solid_multiple_circles_sut(x::Integer, y::Integer)
    
    distance1 = sqrt((x - circle_center_x)^2 + (y - circle_center_y)^2)
    distance2 = sqrt((x - circle_center_x2)^2 + (y - circle_center_y2)^2)
    distance3 = sqrt((x - circle_center_x3)^2 + (y - circle_center_y3)^2)

    if x == 0 && y == 0
        throw(DomainError("The point should not be in the origin (0, 0)"))
    elseif distance1 <= radius_default
        return "Circle"
    elseif distance2 <= radius_default
        return "SecondCircle"
    elseif distance3 <= radius_default
        return "ThirdCircle"  
    else
        return "Outside"
    end

end

function solid_inner_circles_sut(x::Integer, y::Integer)

    distance = sqrt((x - circle_center_x)^2 + (y - circle_center_y)^2)

    if x == 0 && y == 0
        throw(DomainError("The point should not be in the origin (0, 0)"))
    elseif distance <= radius_small
        return "small"
    elseif distance <= radius_medium
        return "medium"
    elseif distance <= radius_large
        return "big"
    else
        return "outside"
    end

end

function dashed_circle_sut(x::Integer, y::Integer)

    angle = atan(y - circle_center_y, x - circle_center_x)
    angle = ifelse(rad2deg(angle) > 0, rad2deg(angle), rad2deg(angle)+360)
    
    distance = sqrt((x - circle_center_x)^2 + (y - circle_center_y)^2)

    if distance <= radius_default && ((angle >= rad2deg(π / 6) && angle <= rad2deg(π / 3)))
        return "red"
    elseif distance <= radius_default && ((angle >= rad2deg(5π / 3) && angle <= rad2deg(11π / 6)))
        return "green"
    elseif distance <= radius_default && ((angle >= rad2deg(7π / 6) && angle <= rad2deg(4π / 3)))
        return "orange"
    elseif distance <= radius_default && ((angle >= rad2deg(2π / 3) && angle <= rad2deg(5π / 6)))
        return "blue"
    end
    
    return "outside"
    
end

circle_center_x, circle_center_y = 0, 0
radius = 80

function sut_solidcircle(args_vec::AbstractVector{<:Any})
    x, y = args_vec[1], args_vec[2]
    distance = sqrt((x - circle_center_x)^2 + (y - circle_center_y)^2)
    if x == 0 && y == 0
        throw(DomainError("The point should not be at the origin (0, 0)"))
    elseif distance <= radius
        return "in"
    else
        return "out"
    end
end

sut_solid_circle(x::Integer, y::Integer) = sut_solidcircle([x, y])
 
circlesolidsut = SUT((x::Integer, y::Integer) -> sut_solid_circle(x,y), "circle solid")
circlemultiplesut = SUT((x::Integer, y::Integer) -> solid_multiple_circles_sut(x,y), "circle multiple")
circleinnersut = SUT((x::Integer, y::Integer) -> solid_inner_circles_sut(x,y), "circle inner")
circlesdashedsut = SUT((x::Integer, y::Integer) -> dashed_circle_sut(x,y), "circle dashed")

# -- Params --
# SUT's:
suts =                        [ circlesolidsut ]
# execution time (seconds):
exectimes =                   [ 30, 600 ]
# alorithms:
algorithms =                  [ :bcs ]
# repetitions:
repetitions  =                22
# sampling strategy:
sss =                          [ BituniformSampling ]
# compatible type sampling investigates the compatible types for an argument, not only the single one defined in the interface
ctss =                         [ true ]

expdir = joinpath("results","circles")
doexperiment(expdir, suts, exectimes, algorithms, repetitions, sss, ctss)
