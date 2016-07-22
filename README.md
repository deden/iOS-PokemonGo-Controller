# iOS PokemonGo Controller

Use your iPad / iPhone as controller.

You will need two iOS device, one for the actual game installed, and the 2nd device as controller. Using iOS simulator as controller is possible (however not tested yet).

You also will need a Mac with Xcode installed to allow simulate GPS location while debugging.

# How to use

- Setup and run [PokemonGo-Map](https://github.com/AHAAAAAAA/PokemonGo-Map). 
- Check if the Flask PokemonGo-Map server already running in browser. Make sure it accessible for your device (through local network).
- In folder Scripts, create folder 'player1', run updateAndClick.py
- Setup this project. Open Xcode workspace, before compiling update the FLASK_SERVER with your Flask PokemonGo-Map server ip address in ViewController.swift.
- Build and run the project to your device. Let's make your player walk. This will trigger controller to ask the updateAndClick.py to create the gpx file (pokemonLocation.gpx) in folder 'player1'.
- Close this Xcode workspace.

- Create a blank Xcode project, drag pokemonLocation.gpx to project. Build and run this blank project into your target device (not your controller device).
- Select Debug -> Simulate Location -> pokemonLocation to enable simulate location in Xcode.
- Open Pokemon Go app.
- Run your controller device, try several movements to check if the Char can move.


# Note
Use at your own risk
##Thanks