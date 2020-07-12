#!/usr/bin/gawk -f
# The following program lets the user attempt landing on a selected planet's surface. 
# Planet and rocket data are supplied in the program.

# Program Usage: ./lander.awk
#
# Created by Sasha Shkolnikov. July 12, 2020.

# All Rights Reserved.
#

BEGIN {

    FS = ":"                    # Set the 'planets' field separator, as of line 3
    IGNORECASE = 1              # Set to non-zero value to have all regexp and string operations ignore case. 

    mass_o = 0                   # Lander + fuel mass at start, in kgs
    mass_c = 0                   # Lander + fuel mass at current time, in kgs

    fuel_o = 0                   # Lander fuel amount at start in kgs
    fuel_rem = 0                   # Lander remaining fuel amount at current time, in kgs
    fuel_d = 0                   # Delta fuel amount in kgs
    fuel_cons=0                  # Fuel consumption rate, in kg/sec

    vel_o = 0                  # Lander velocity at start, in m/sec
    vel_c = 0                  # Lander velocity at current time, in m/sec
    vel_d = 0                   # Change in velocity, in m/sec
    vel_eff = 0                 # Effective rocket exhaust velocity, in m/sec

    height_o = 500                  # Original lander height from planet surface, in m
    height_c = 0                   # Updated lander height from planet surface: h = ho + vo Δt + a (Δt)2 / 2, in m

    time_o  = 0                  # Time elapsed from start, in sec
    time_d =  1                  # Delta t, or unit of change in time, in sec
    time_c =  0                  # Currently updated elapsed time from start, in sec

    gravity = 0                 # Gravity acceleration on selected planets
    accel_o = 0                   # Original lander acceleration:
    accel_c = 0                   # Current lander acceleration: accel_c = accel_o + gravity

    engine_burn = 0               # zero burn
    spacex40 = "                                        "
    landing_done = 0


    # Flight Equations used:

    # Fuel:         fuel_rem = fuel_o - fuel_d;             fuel_d = fuel_cons * time_d
    # Velocity      vel_c = vel_o + (vel_d * time_d);     vel_d = vel_eff * ln(mass_o/mass_c) - gravity * time_d
    # Time          time_c = time_o + time_d
    # Height        height_c = height_o + (vel_o * time_d) + accel_c * (time_d)^2 / 2
    # Acceleration  accel_c = vel_d / time_d
    # Mass          mass_c = mass_o - fuel_d




    # Initialize planets' gravity into planets array

    planets["MERCURY"] = 3.7
    planets["VENUS"] = 8.87
    planets["EARTH"] = 9.807
    planets["MARS"] = 3.711
    planets["JUPITER"] = 24.79
    planets["SATURN"] = 10.44
    planets["URANUS"] = 8.69
    planets["NEPTUNE"] = 11.15
    planets["PLUTO"] = 0.62
    planets["TITAN"] = 1.352
    planets["IO"] = 1.796
    planets["EUROPA"] = 1.315
    planets["GANYMEDE"] = 1.428
    planets["MOON"] = 1.62

    # Initialize rocket's data into rockets array

    rocket["eff_vel"] = 22500 
    rocket["fuel_cons"] = 0.5 
    rocket["mass_full"] = 31500 
    rocket["fuel_mass"] = 100 

    # Initialize color escape codes
    
    Color_Off   =   "\033[0m"       # Normal, Text Reset
    Yellow      =   "\033[0;33m"    # Yellow
    Green       =   "\033[0;32m"    # Green
    Red         =   "\033[0;31m"     # Red
    BYellow     =   "\033[1;33m"    # Bold Yellow
    BBlue       =   "\033[1;34m"    # Bold Blue
    BRed        =   "\033[1;31m"    # Bold Red
    BGreen      =   "\033[1;32m"    # Bold Green
    
    game = 1
    while(game == 1)
    {
        system("clear")

        printf(spacex40); printf("    Planets available for landing")
        print; print
        print(Yellow)
        for(item in planets)
        {
            printf(spacex40); printf("Planet %8s has gravity of%8.3f m/sec^2 \n", item, planets[item])
        }
        print ""
        print(Color_Off)
        printf(spacex40); printf("Select planet to land on: ")
        getline planet < "/dev/stdin"
        planet = toupper(planet)
        if (planet in planets)
        {
            printf(spacex40); print("You have chosen: ", BRed planet Color_Off)
            print
            print

            # Initialize variables from rockets and planets arrays
            gravity = planets[planet]
            mass_o = rocket["mass_full"]
            mass_c = mass_o
            fuel_o = rocket["fuel_mass"]
            fuel_rem = fuel_o
            time_c = time_o
            vel_c = vel_o
            height_c = height_o
            number_of_burns = 0
            
            # Print initial flight variable values. 

            print(BBlue)
            printf ("%40s %20s %22s %14s %19s %22s \n", spacex40, "TIME (s)", "VELOCITY (m/s)", "HEIGHT (m)", "FUEL (kg)", "ENGINE BURN (0-10)")
            print(Color_Off)
            print ""
            printf ("%40s %15d %20.4f %20.4f %20.4f %15.2f\n", spacex40, time_c, vel_c, height_c, fuel_rem, engine_burn)

            landing_done = 0
            while(landing_done == 0)
            {
                printf(BYellow)
                printf("Select engine burn (0 to 10): ")
                printf(Color_Off)
                getline engine_burn < "/dev/stdin"
                if ((engine_burn < 0) || (engine_burn > 10))
                    print("Incorrect selection!")
                else
                {
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

                    time_c = time_c + time_d
                    fuel_d = fuel_cons * time_d
                    fuel_rem = fuel_rem - fuel_d
                    mass_c = mass_c - fuel_d
                    vel_d = vel_eff * log(mass_o/mass_c) - (gravity * time_d)
                    accel_c = vel_d / time_d
                    vel_c = vel_c + (vel_d * time_d)
                    height_c = height_c + (vel_c * time_d) + (accel_c * (time_d)^2 ) / 2
                    
                    if ((number_of_burns > 0) && (number_of_burns % 22 == 0))
                    {
                        print(BBlue)
                        printf ("%40s %20s %22s %14s %19s %22s \n", spacex40, "TIME (s)", "VELOCITY (m/s)", "HEIGHT (m)", "FUEL (kg)", "ENGINE BURN (0-10)")
                        print(Color_Off)
                    }
                    if((fuel_rem < 25) || (vel_c > 0) || (height_c < 25))
                        print(Red)
                    else
                        print(Green)
                    printf ("%40s %15d %20.4f %20.4f %20.4f %15.2f\n", spacex40, time_c, vel_c, height_c, fuel_rem, engine_burn)
                    print(Color_Off)
                    
                    if (fuel_rem <= 0)
                    {
                        if ((height_c <= 5) && (abs(vel_c) <= 3))
                        {
                            print
                            print(BGreen)
                            print (spacex40, "*** Out of fuel, but landing was soft! ***")
                            print(Color_Off)
                        }
                        else
                        {   print
                            print(BRed)
                            print (spacex40, "*** Out of fuel, and hard crashed!! ***")
                            print(Color_Off)
                        }

                        landing_done = 1
                    }

                    if (height_c <= 0)
                    {
                        if (abs(vel_c) <= 3)
                        {   print
                            print(BGreen)
                            print (spacex40, "*** Congratulations, your landing was soft! ***")
                            print(Color_Off)
                        }
                        else
                        {   print
                            print(BRed)
                            print (spacex40, "*** Sorry, you hard crashed!! ***")
                            print(Color_Off)
                        }
                        landing_done = 1
                    } # End If
                } # End Else
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
        }
    } # End while(game == 1)
} # End Begin


function abs(value)
{
    if(value < 0)
        return (value * -1)
    else
        return (value)
}
