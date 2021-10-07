
# Must add CSV, ReadStat, DataFrames and Gadfly packages needed for this project
# import Pkg; Pkg.add("Pkg")
# Pkg.add("CSV")
# Pkg.add("ReadStat")
# Pkg.add("DataFrames")
# Pkg.add("Gadfly")
# Pkg.add("Compose")
# Pkg.add("StatFiles")
# Pkg.add("VegaLite") 
# Pkg.add("VegaDatasets")
#import Pkg; Pkg.add("JSON")
#import Pkg; Pkg.add("Requests") 
#Pkg.clone("https://github.com/plotly/Plotly.jl")
#import Pkg; Pkg.add("Plotly")



# Don't add NodeJS but know that it is needed.
# Pkg.add("NodeJS")
# Pkg.build("NodeJS")

# Pkg.add("VegaLite") 
# Pkg.add("VegaDatasets")
# Pkg.add("DataVoyager")
# Pkg.add("IJulia")
# Pkg.build("VegaLite")


# Load required libraries
# using DataFrames, CSV, Gadfly, Compose, ReadStat, StatFiles, VegaLite, VegaDatasets;
using DataFrames, CSV, Gadfly, StatFiles, ReadStat

# Read tables using the updated CSV.jl package v0.5.3
   demo17q2 = CSV.read("C:\\Users\\churley\\data\\DEMO17Q2.txt"; header = 1, delim = '$')
   drug17q2 = CSV.read("C:\\Users\\churley\\data\\DRUG17Q2.txt"; header = 1, delim = '$')
   indi17q2 = CSV.read("C:\\Users\\churley\\data\\INDI17Q2.txt"; header = 1, delim = '$')
   outc17q2 = CSV.read("C:\\Users\\churley\\data\\OUTC17Q2.txt"; header = 1, delim = '$')
   reac17q2 = CSV.read("C:\\Users\\churley\\data\\REAC17Q2.txt"; header = 1, delim = '$')
   rpsr17q2 = CSV.read("C:\\Users\\churley\\data\\RPSR17Q2.txt"; header = 1, delim = '$')
   ther17q2 = CSV.read("C:\\Users\\churley\\data\\THER17Q2.txt"; header = 1, delim = '$')
#    ther17q2 = CSV.read("C:\\Users\\churley\\data\\THER17Q2.txt"; header = 1, delim = '$', datarow=195880)

# Read SAS data using a function from the StatFiles package 
# using StatFiles, DataFrames
# Can't use MedDRA because of licensing 
# meddra20 = load("C:\\Users\\churley\\data\\meddra20_0.sas7bdat") |> DataFrame
# m20=read_sas7bdat("C:\\Users\\churley\\data\\meddra20_0.sas7bdat")
# meddra20=DataFrame(m20.data,m20.headers)

# There are some columns that need to be renamed.
# We can envision a future state where this is automated... for now manual.
indi17q2 = rename(indi17q2, :indi_drug_seq => :drug_seq)
ther17q2 = rename(ther17q2, :dsg_drug_seq => :drug_seq);

# For proof-of-concept speed purposes, we will use only the first 10,000 rows of each dataset.
demo17q2 = first(demo17q2, 10000)
drug17q2 = first(drug17q2, 10000)
indi17q2 = first(indi17q2, 10000)
outc17q2 = first(outc17q2, 10000)
reac17q2 = first(reac17q2, 10000)
rpsr17q2 = first(rpsr17q2, 10000)
ther17q2 = first(ther17q2, 10000);

########## Perform joins
# Pull in indications for use into drug file table
drug_ind = join(
    drug17q2[:, [:primaryid, :caseid, :drug_seq, :drugname, :route, :cum_dose_chr, :dose_amt,
        :dose_unit, :dose_form, :dose_freq, :role_cod]],
    indi17q2[:, [:primaryid, :drug_seq, :indi_pt]],
    on = [:primaryid, :drug_seq], kind = :left
)

drug_ind_ther = join(
    drug_ind, ther17q2[:, [:primaryid, :drug_seq, :start_dt, :end_dt, :dur, :dur_cod]],
    on = [:primaryid, :drug_seq], kind = :left
)

# Pull reaction data into patient demographic table
demo_reac = join(
    demo17q2[:, [:primaryid, :caseid, :event_dt, :age, :age_cod, :age_grp, :sex, :wt, :occr_country]],
    reac17q2[:, [:primaryid, :pt, :drug_rec_act]],
    on = :primaryid, kind = :left,
)

# Pull outcomes information into the previous table
demo_reac_out = join(
    demo_reac, outc17q2[:, [:primaryid, :outc_cod]], on = :primaryid, kind = :left
)

# Concatenate previous table with report source information
demo_reac_out_source = join(
    demo_reac_out, rpsr17q2[:, [:primaryid, :rpsr_cod]], on = :primaryid, kind = :left
)

# Lastly, join the (Drug/Therapy/Indication) and (Demographic/Reaction/Outcome/Report Source)
# combined sets into one set with all this information in one place.
#faers17 = join(drug_ind_ther, delete!(demo_reac_out_source, :caseid), on = :primaryid, kind = :left);
faers17 = join(drug_ind_ther, deletecols!(demo_reac_out_source, :caseid), on = :primaryid, kind = :left);
########## End joins

########## Perform transformations
# Begin by storing a vector of counts by PT, where PT is "Preferred Term", or the event.
faers17q2_1 = by(faers17, :pt, d -> DataFrame(count_pt_17q2 = nrow(d)))

# Append this vector to the combined FAERS dataset.
faers17q2_2 = join(faers17, faers17q2_1, on = :pt, kind = :left, makeunique = true)

# Create a vector of counts by combination of Drug, and PT.
faers17q2_3 = by(faers17q2_2, [:drugname, :pt],
    d -> DataFrame(count_dpt_17q2 = nrow(d)))

#
faers17q2_4 = join(faers17q2_2, faers17q2_3, on = [:drugname, :pt], kind = :left,
    makeunique = true)

faers17q2_4[:count_percentage_17q2] =
    (faers17q2_4[:count_dpt_17q2] ./ faers17q2_4[:count_pt_17q2]) .* 100;
########## End transformations

#Show dataframe faers17q2_1

withenv("LINES" => 5) do
    display(faers17q2_1)
end

#Show dataframe faers17q2_1

withenv("LINES" => 5) do
    display(faers17q2_2)
end

#Show dataframe faers17q2_1

withenv("LINES" => 5) do
    display(faers17q2_3)
end

#Show dataframe faers17q2_1

withenv("LINES" => 5) do
    display(faers17q2_4)
end

# View final dataset.  ETL is complete.
first(faers17q2_4, 10)

# Exploring with the describe() function:
drug_case_pct = faers17q2_4[:count_percentage_17q2]

describe(drug_case_pct)

# Isolate the pilot drug
pilot_data = faers17q2_4[faers17q2_4[:drugname] .== "ATACAND", :]

# Adverse events by country
# Bar chart for now.  Consider the JuliaGeo library
d1 = unique(faers17q2_4[:, [:primaryid, :pt, :occr_country]])
d2 = by(d1, :occr_country,
    d -> DataFrame(Frequency = nrow(d)))
sort!(d2, :Frequency, rev = true)

Gadfly.plot(d2, x = :occr_country, y = :Frequency, Geom.bar,
    Guide.xlabel("Country"),
    Guide.ylabel("Frequency"),
    Guide.title("Adverse Events by Country"),
    Scale.y_continuous(format=:plain),
    Theme(default_color = "red"))

#VegaLite data presentation will use data from all drugs
d1 = unique(faers17q2_4[:, [:primaryid, :sex, :pt, :occr_country, :drugname]])
d2 = by(d1, [:occr_country, :sex, :drugname], 
    d -> DataFrame(Frequency = nrow(d)))
sort!(d2, :Frequency, rev = true)
rename!(d2, :sex => :gender)
allc = first(d2,60)




#Julia visualization remove after figuring out how to use vegalite
using VegaLite, VegaDatasets

allc |> @vlplot(:bar, 
        x={"occr_country:n", axis={title="Country"}},
        title="Adverse Events by Country and Gender", 
        y={:Frequency, axis={title="Number of AEs"}}, 
        color={"gender:n", scale={range=["#1f77b4","#e377c2"]}},
        height=400,
        width=600)



allc |> @vlplot(:bar, 
        

        x={"occr_country:n", axis={title="Country"}},
        title="Adverse Events by Country and Gender - Atacand Only", 
        y={:Frequency, axis={title="Number of AEs"}}, 
        color={"gender:n", scale={range=["#1f77b4","#e377c2"]}},
        height=400,
        width=600)

Pkg.add("PlotlyJS")

using PlotlyJS

# Adverse events by gender
d2 = unique(faers17q2_4[:, [:primaryid, :pt, :sex]])
d2 = by(d2, :sex,
    d -> DataFrame(Frequency = nrow(d)))
d2[1, :sex] = "Unknown"

palette = ["grey", "blue", "pink"]
# labels = string(d2[:, :Frequency])
# labels

Gadfly.plot(d2, x = :sex, label = 1, y = :Frequency, color = :sex, Geom.bar, 
    Geom.label(position = :above),
    Guide.xlabel("Gender"),
    Guide.ylabel("Frequency"),
    Guide.title("Adverse Events by Gender"),
    Scale.y_continuous(format=:plain),
    Scale.color_discrete_manual(palette...)
    #Guide.annotation(compose(context(), text(:sex, :Frequency, labels)))
    )

describe(d2)

# Adverse events by age group
d3 = unique(faers17q2_4[:, [:primaryid, :pt, :age_grp]])
d3 = by(d3, :age_grp,
    d -> DataFrame(Frequency = nrow(d)))
d3[1, :age_grp] = "Unknown"

Gadfly.plot(d3, x = :age_grp, y = :Frequency, color = :age_grp, Geom.bar,
    Guide.xlabel("Age Group"),
    Guide.ylabel("Frequency"),
    Guide.title("Adverse Events by Age Group"),
    Scale.y_continuous(format=:plain),
    Guide.colorkey("Legend")
    )

# Adverse events by role of the drug
d4 = unique(faers17q2_4[:, [:primaryid, :pt, :role_cod]])
d4 = by(d4, :role_cod,
    d -> DataFrame(Frequency = nrow(d)))

Gadfly.plot(d4, x = :role_cod, y = :Frequency, color = :role_cod, Geom.bar,
    Guide.xlabel("Role of the Drug"),
    Guide.ylabel("Frequency"),
    Guide.title("Adverse Events by Drug Role"),
    Scale.y_continuous(format=:plain),
    Guide.colorkey("Legend")
    )

d5 = unique(faers17q2_4[:, [:primaryid, :pt]])
d5 = by(d5, :pt,
    d -> DataFrame(Frequency = nrow(d)))
names!(d5, [:Adverse_Event, :AEs_in_2017_Q2])
#rename!(d5, :pt => :Adverse_Event)
sort!(d5, :AEs_in_2017_Q2, rev = true)

#VegaLite data presentation
head(d5,10)

#Julia visualization remove after figuring out how to use vegalite
using VegaLite, VegaDatasets

data = dataset("cars")

data |> @vlplot(:point, 
        x= "Cylinders:o",
        title="Number of Cylinders", 
        y=:Miles_per_Gallon, 
        color="Origin:n",
        height=400,
        width=300)

#data |> @vlplot(:point) |> display

#using VegaLite

#d5 |> @vlplot(:point, x=:AEs_in_2017_Q2, y=:Adverse_Event)


Pkg.add("Query")

using VegaLite, VegaDatasets

dataset("gapminder-health-income") |>
@vlplot(
    :circle,
    width=500,height=300,
    selection={
        view={typ=:interval, bind=:scales}
    },
    y={:health, scale={zero=false}},
    x={:income, scale={typ=:log}},
    size=:population,
    color={value="#000"}
)

using VegaLite, VegaDatasets

us10m = dataset("us-10m").path
unemployment = dataset("unemployment.tsv").path

@vlplot(
    :geoshape,
    width=500, height=300,
    data={
        url=us10m,
        format={
            typ=:topojson,
            feature=:counties
        }
    },
    transform=[{
        lookup=:id,
        from={
            data=unemployment,
            key=:id,
            fields=["rate"]
        }
    }],
    projection={
        typ=:albersUsa
    },
    color="rate:q"
)

using VegaLite, DataFrames

x = [j for i in -5:4, j in -5:4]
y = [i for i in -5:4, j in -5:4]
z = x.^2 .+ y.^2
data = DataFrame(x=vec(x'),y=vec(y'),z=vec(z'))

data |> @vlplot(:rect, x="x:o", y="y:o", color=:z)
