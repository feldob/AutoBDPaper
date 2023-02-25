# four software under test are investigated for the investigation of interesting boundary candidates, i.e. pairs of nearby inputs that produce very different outputs.

sutnames = ["bytecount", "BMI", "BMI classification", "Julia Date"]

#------------------------------------------------#
# bytecount
#------------------------------------------------#
# bytecount, most copied code snippet on Stackoverflow which happens to be buggy (from Java, adjusted to Julia). Already part of AutoBVA.

function byte_count_bug(bytes::Integer, si::Bool = true)
    unit = si ? 1000 : 1024
    if bytes < unit
        return string(bytes) * "B"
    end
    exp = floor(Int, log(bytes) / log(unit))
    pre = (si ? "kMGTPE" : "KMGTPE")[exp] * (si ? "" : "i")
    @sprintf("%.1f %sB", bytes / (unit^exp), pre)
end

function byte_count_corrected(bytes::Integer, si::Bool = true)
    unit = si ? 1000 : 1024
    absBytes = bytes == typemax(Int64) ? typemax(Int64) : abs(bytes)

    if bytes < unit
        return string(bytes) * "B"
    end

    exp = floor(Int, log(bytes) / log(unit))
    th = trunc(Int128,unit^exp * (unit - 0.05))

    if (exp < 6 && absBytes >= th - ((th & 0xfff) == 0xd00 ? 52 : 0))
        exp = exp + 1
    end

    pre = (si ? "kMGTPE" : "KMGTPE")[exp] * (si ? "" : "i")
    if (exp > 4)
        bytes = div(bytes, unit)
        exp = exp - 1
    end

    @sprintf("%.1f %sB", bytes / (unit^exp), pre)
end

# 3 implementations, of which se use the second, the corrected buggy version, in the study
bytecountbugsut = SUT((bytes::Integer) -> byte_count_bug(bytes), "bytecount buggy")

bytecountsut = SUT((bytes::Integer) -> byte_count_corrected(bytes), "bytecount")

# Julia built in version not used in study:
bytecountjuliasut = SUT((bytes::Integer) -> Base.format_bytes(bytes), "bytecount julia")

#------------------------------------------------#
# BMI numeric
#------------------------------------------------#

#To avoid using doubles, we receive an integer height in CM!
function bmi(height::Integer, weight::Integer)
    if height < 0 || weight < 0
        throw(DomainError("Height or Weight cannot be negative."))
    end
    heigh_meters = height / 100 # Convert height from cm to meters
    bmivalue = round(weight / heigh_meters^2, digits = 1) # official standard expects 1 decimal after the comma
    return (bmivalue)
end

function bmi_tostring(height::Integer, weight::Integer)
    bmivalue = bmi(height,weight)
    @sprintf "%.1f" bmivalue
end

bmisut = SUT((h::Int64, w::Int64) -> bmi_tostring(h, w), "BMI")

#------------------------------------------------#
# BMI classification
#------------------------------------------------#

function bmi_classification(height::Integer, weight::Integer)
    bmivalue = bmi(height,weight)
    class = ""
    if bmivalue < 0
        throw(DomainError(bmivalue, "BMI was negative. Check your inputs: $(height) cm; $(weight) kg"))
    elseif bmivalue < 18.5
        class = "Underweight"
    elseif bmivalue < 23
        class = "Normal"
    elseif bmivalue < 25
        class = "Overweight"
    elseif bmivalue < 30
        class = "Obese"
    else class = "Severely obese"
    end
    return class
end

bmiclasssut = SUT((h::Int64, w::Int64) -> bmi_classification(h, w), "BMI classification")

#------------------------------------------------#
# Julia Dates
#------------------------------------------------#

datesut = SUT((year::Int64, month::Int64, day::Int64) -> Date(year, month, day), "Julia Date")

bve_suts = Dict()
bve_suts[AutoBVA.name(datesut)] = datesut
bve_suts[AutoBVA.name(bmiclasssut)] = bmiclasssut
bve_suts[AutoBVA.name(bmisut)] = bmisut
bve_suts[AutoBVA.name(bytecountsut)] = bytecountsut