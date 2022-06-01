using DataFrames
using Plots

# Earth radius
rₑ = 6371E3 # m

# Earth standard gravatational parameter
μ = 3.986E14 # m^3/s^2

# Gravity
g = 9.80665 # m/s^2

# Station parameters
station_altitude = 300E3 # m
station_inclination = 20 # deg

# Tug parameters
tug_dry_mass = 1000E3 # g
tug_isp = 350 # s
tug_vₑ = tug_isp * g # m/s

# Client parameters
client_mass = 1000E3 # g
client_altitude = 150E3:10E3:450E3 # m
client_inlcination = 0 # deg

function hohman(alt₁, alt₂)
    # Radius of orbital altitudes
    r₁ = alt₁ + rₑ # m
    r₂ = alt₂ + rₑ # m

    # Enter eliptical orbit at r = r₁
    Δv₁ = sqrt(μ / r₁) * (sqrt(2 * r₂ / (r₁ + r₂)) - 1) # m/s

    # Exit eliptical orbit at r = r₂
    Δv₂ = sqrt(μ / r₂) * (1 - sqrt(2 * r₁ / (r₁ + r₂))) # m/s

    # Total Δv
    Δv = Δv₁ + Δv₂ # m/s
 
    return Δv # m/s
end

function inclination(alt, Δi)
    # Radius of orbital altitudes
    r = alt + rₑ # m

    # Velocity of circular orbit
    v = sqrt(μ / r) # m/s

    # Δv of inclination change
    Δv = 2 * v * sin(Δi / 2) # m/s

    return Δv # m/s
end

function tsiolkovsky(Δv, dry_mass)
    wet_mass = dry_mass * ℯ^(Δv / tug_vₑ) # g

    return wet_mass # g
end

# Mission: rendezvous with client, dock, return to station with client
function propellant_mass(client_altitude, client_inclination)
    mission = Tuple{Float64, Float64}[]

    # Inclination change
    Δi = (client_inclination - station_inclination) * 0.0174533 # rad

    # Depending on if the client is above or below the station the Δv requirments of the 
    # inclination change manouver will change
    if(station_altitude > client_altitude)
        # Match client altitude
        Δv = abs(hohman(station_altitude, client_altitude)) # m/s
        m = tug_dry_mass
        push!(mission, (Δv, m))

        # Match client inclination
        Δv = abs(inclination(client_altitude, Δi)) # m/s
        m = tug_dry_mass
        push!(mission, (Δv, m))
        
        # Dock

        # Match station inclination
        Δv = abs(inclination(client_altitude, -Δi)) # m/s
        m = tug_dry_mass + client_mass
        push!(mission, (Δv, m))

        # Match station altitude
        Δv = abs(hohman(client_altitude, station_altitude)) # m/s
        m = tug_dry_mass + client_mass
        push!(mission, (Δv, m))
    else
        # Match client inclination
        Δv = abs(inclination(station_altitude, Δi)) # m/s
        m = tug_dry_mass
        push!(mission, (Δv, m))

        # Match client altitude
        Δv = abs(hohman(station_altitude, client_altitude)) # m/s
        m = tug_dry_mass
        push!(mission, (Δv, m))
        
        # Dock

        # Match station altitude
        Δv = abs(hohman(client_altitude, station_altitude)) # m/s
        m = tug_dry_mass + client_mass
        push!(mission, (Δv, m))

        # Match station inclination
        Δv = abs(inclination(station_altitude, -Δi)) # m/s
        m = tug_dry_mass + client_mass
        push!(mission, (Δv, m))
    end

    # Work backwards from each step in the mission to determine the total propellant mass requirment
    propellant_mass = 0
    for i in length(mission):-1:1
        Δv = mission[i][1]
        m = mission[i][2] + propellant_mass
        wet_mass = tsiolkovsky(Δv, m)

        propellant_mass = propellant_mass + wet_mass - m
    end
    
    return propellant_mass
end

plot(client_altitude / 1E3, propellant_mass.(client_altitude, client_inlcination) / 1E3, title = "Orbital Altitude Sensitivity Sweep")
xlabel!("Orbital Altitude (km)")
<<<<<<< refs/remotes/origin/main
ylabel!("Propellant Mass (kg)")
=======
ylabel!("Propellant Mass (kg)")
>>>>>>> Initial commit
