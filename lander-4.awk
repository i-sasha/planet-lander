#!/usr/bin/gawk -f
# The following program lets the user attempt landing on a selected planet's surface. 
# Planet and rocket data are supplied in the program.

# Program Usage: ./lander.awk
#
# Authored by Sasha Shkolnkov, July 2, 2020
# Feel free to use, modify and share.


BEGIN {

    FS = ":"                    # Set the 'planets' field separator, as of line 3
    IGNORECASE = 1              # Set to non-zero value to have all regexp and string operations ignore case. 

    mass_o = 0                  # Lander + fuel mass at start, in kgs
    mass_c = 0                  # Lander + fuel mass at current time, in kgs

    fuel_o = 0                  # Lander fuel amount at start in kgs
    fuel_rem = 0                # Lander remaining fuel amount at current time, in kgs
    fuel_d = 0                  # Delta fuel amount in kgs
    fuel_cons = 0               # Fuel consumption rate, in kg/sec

    vel_o = 0                   # Lander velocity at start, in m/sec
    vel_c = 0                   # Lander velocity at current time, in m/sec
    vel_d = 0                   # Change in velocity, in m/sec
    vel_eff = 0                 # Effective rocket exhaust velocity, in m/sec

    height_o = 1000             # Original lander height from planet surface, in m
    height_c = 0                # Updated lander height from planet surface: h = ho + vo Δt + a (Δt)2 / 2, in m

    time_o  = 0                 # Time elapsed from start, in sec
    time_d =  1                 # Delta t, or unit of change in time, in sec
    time_c =  0                 # Currently updated elapsed time from start, in sec

    gravity = 0                 # Gravity acceleration on selected planets
    accel_o = 0                 # Original lander acceleration:
    accel_c = 0                 # Current lander acceleration: accel_c = accel_o + gravity

    engine_burn = 0             # zero burn
    prev_burn = 0               # to enable repetitive inputs
    prev_time_d = 1             # to enable repetitive inputs
    spacex40 = "                                        "
    landing_done = 0


    # Flight Equations used:

    # Fuel:         fuel_rem = fuel_o - fuel_d;             fuel_d = fuel_cons * time_d
    # Velocity      vel_c = vel_o + (vel_d * time_d);       vel_d = vel_eff * ln(mass_o/mass_c) - gravity * time_d
    # Time          time_c = time_o + time_d
    # Height        height_c = height_o + (vel_o * time_d) + accel_c * (time_d)^2 / 2
    # Acceleration  accel_c = vel_d / time_d
    # Mass          mass_c = mass_o - fuel_d




    # Initialize planets' gravity into planets array

    planets["MERCURY"]  = 3.7
    planets["VENUS"]    = 8.87
    planets["EARTH"]    = 9.807
    planets["MARS"]     = 3.711
    planets["JUPITER"]  = 24.79
    planets["SATURN"]   = 10.44
    planets["URANUS"]   = 8.69
    planets["NEPTUNE"]  = 11.15
    planets["PLUTO"]    = 0.62
    planets["TITAN"]    = 1.352
    planets["IO"]       = 1.796
    planets["EUROPA"]   = 1.315
    planets["GANYMEDE"] = 1.428
    planets["MOON"]     = 1.62

    # Initialize rocket's data into rockets array

    rocket["eff_vel"] = 500         # m/sec
    rocket["fuel_cons"] = 5         # kg/sec
    rocket["mass_full"] = 31500     # kg
    rocket["fuel_mass"] = 20000     # kg

    # Initialize color escape codes
    
    Color_Off   =   "\033[0m"       # Normal, Text Reset
    Yellow      =   "\033[0;33m"    # Yellow
    Green       =   "\033[0;32m"    # Green
    Red         =   "\033[0;31m"    # Red
    BYellow     =   "\033[1;33m"    # Bold Yellow
    BBlue       =   "\033[1;34m"    # Bold Blue
    BRed        =   "\033[1;31m"    # Bold Red
    BGreen      =   "\033[1;32m"    # Bold Green
    
    game = 1
    while(game == 1)
    {
        system("clear")

        printf(spacex40); printf("    Planets and Satellites available for landing")
        print; print
        printf(Yellow)
        for(item in planets)
        {
            printf(spacex40); printf("Planet/Satellite %8s has gravity of%8.3f m/sec^2 \n", item, planets[item])
        }
        print ""
        
        do
        {
            
            printf(Color_Off)
            printf(spacex40); printf("Select planet/satellite to land on: ")
            getline planet < "/dev/stdin"
            planet = toupper(planet)

            done = 1
            found = (planet in planets)
            if (! found)
            {
                printf("%40s %s \n\n", spacex40, "Incorrect selection!")
                done = 0
            }
        } while (! done)
        
        printf(spacex40); print("You have chosen: ", BRed planet Color_Off)
        print
        print

        # Initialize variables from rockets and planets arrays
        gravity     = planets[planet]
        mass_o      = rocket["mass_full"]
        mass_c      = mass_o
        fuel_o      = rocket["fuel_mass"]
        fuel_rem    = fuel_o
        time_c      = time_o
        vel_c       = vel_o
        height_c    = height_o
        engine_burn = 0
        prev_burn   = 0
        prev_time_d = 1
            
        # Print initial flight variable values. 

        printf(BBlue)
            
        printf("\n%40s %20s %10d sec\n", spacex40, "time elapsed:", time_c)
        printf("%40s %20s %10d units\n", spacex40, "engine burn:", engine_burn)
        printf("%40s %20s %10d m/sec\n", spacex40, "current velocity:", vel_c)
        printf("%40s %20s %10d m\n", spacex40, "current height:", height_c)
        printf("%40s %20s %10d kg\n", spacex40, "fuel available:", fuel_rem)
            
        printf("%40s %30s \n", spacex40, "================================")
        printf(Color_Off)

        landing_done = 0
        while(landing_done == 0)
        {
            do
            {
                printf(BYellow)
                printf("\n\n%40s %s", spacex40, "Enter engine burn time period in seconds: ")
                printf(Color_Off)
                getline time_d < "/dev/stdin"
                    
                if (time_d == "")
                {
                    time_d = prev_time_d
                    done = 1
                }
                    
                if ((time_d <= 0) || (!isnum(time_d)))
                {
                    printf("%40s %s \n\n", spacex40, "Incorrect selection!")
                    done = 0
                }
                else
                    done = 1

            } while (! done)
                
            done = 0
            do
            {
                    
                printf(BYellow)
                printf("%40s %s", spacex40, "Enter engine burn (0 to 10): ")
                printf(Color_Off)
                getline engine_burn < "/dev/stdin"
                
                if (engine_burn == "")
                {
                    engine_burn = prev_burn
                    done = 1
                }
                    
                if ((engine_burn < 0) || (engine_burn > 10))
                {
                        
                    printf("%40s %s \n\n", spacex40, "Incorrect selection!")
                    done = 0
                }
                    
                else
                    done = 1
                    
            } while (! done)
                
                        
            # Perform re-calculations of landing variables

            if (engine_burn == 0)
            {
                fuel_cons = 0
                vel_eff = 0
            }
                
            else
            {
                fuel_cons = engine_burn * rocket["fuel_cons"]
                vel_eff = engine_burn * rocket["eff_vel"]
            }

            time_c   = time_c + time_d
            fuel_d   = fuel_cons * time_d
            fuel_rem = fuel_rem - fuel_d
            mass_c   = mass_c - fuel_d
            vel_d    = vel_eff * log(mass_o/mass_c) - (gravity * time_d)
            accel_c  = vel_d / time_d
            vel_c    = vel_c + (vel_d * time_d)
            height_c = height_c + (vel_c * time_d) + (accel_c * (time_d)^2 ) / 2
                    
            printf("\n%40s %20s %10.3f sec\n", spacex40, "time elapsed:", time_c)
            printf("%40s %20s %10.3f units\n", spacex40, "engine burn:", engine_burn)
            printf(Green)
                    
            if (vel_c >= 0)
            {
                printf(Red)
                printf("%40s %20s %10.3f m/sec - Going up!\n", spacex40, "current velocity:", vel_c)
                printf(Green)
            }
                
            else
                printf("%40s %20s %10.3f m/sec\n", spacex40, "current velocity:", vel_c)
                        
                    
            if (height_c <= 25)
            {
                printf(Red)
                printf("%40s %20s %10.3f m - Watch the height!\n", spacex40, "current height:", height_c)
                printf(Green)
            }
                    
            else
                printf("%40s %20s %10.3f m\n", spacex40, "current height:", height_c)
                        
                    
            if (fuel_rem <= 50)
            {
                printf(Red)
                printf("%40s %20s %10.3f kg - Low on fuel!\n", spacex40, "fuel available:", fuel_rem)
                printf(Green)
            }
                
            else
                printf("%40s %20s %10.3f kg\n", spacex40, "fuel available:", fuel_rem)
                        
                                        
            printf("%40s %30s \n", spacex40, "================================")

            printf(Color_Off)
                    
            prev_burn = engine_burn
            prev_time_d = time_d
                    
            if (fuel_rem <= 0)
            {
                if ((height_c <= 5) && (abs(vel_c) <= 3))
                {
                    print
                    printf(BGreen)
                    print (spacex40, "*** Out of fuel, but landing was soft! ***")
                    printf(Color_Off)
                }
                    
                else
                {   
                    print
                    printf(BRed)
                    print (spacex40, "*** Out of fuel, and hard crashed!! ***")
                    printf(Color_Off)
                }

                landing_done = 1
            }

            if (height_c <= 0)
            {
                if (abs(vel_c) <= 3)
                {   
                    print
                    printf(BGreen)
                    print (spacex40, "*** Congratulations, your landing was soft! ***")
                    printf(Color_Off)
                }
                    
                else
                {   
                    print
                    printf(BRed)
                    print (spacex40, "*** Sorry, you hard crashed!! ***")
                    printf(Color_Off)
                }
                landing_done = 1
            } # End If

            
        } # while(landing_done == 0)

        printf(BBlue)
        printf(spacex40);
        printf("     Another game? (y/n): ")
        printf(Color_Off)
        getline game < "/dev/stdin"
        answer = tolower(game)
        if (answer == "n")
            game = 0
        else
            game = 1

        
    } # End while(game == 1)

    
} # End Begin


function abs(value)
{
    if(value < 0)
        return (value * -1)
    else
        return (value)
}

function isnum(x)
{
    return(x==x+0)
}
