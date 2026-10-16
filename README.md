# Introduction

Welcome to the early development repository for my upcoming 2D game, built in Godot 4.

I've decided to make the project open source from day one. Game development is a constant learning process, and I wanted to share the foundational steps of building this game's core mechanics.

Right now, the project is entirely focused on the most important part of any platformer/action game: how the character feels to control.

# Controls

### Keyboard
| Key | Action |
| :---: | :---: |
| D / Right Arrow | Walk Right |
| A / Left Arrow | Walk Left |
| W / UP Arrow | Jump |
| Ctrl | Sneak / Crouch |
| Shift | Sprint / Run |

### Controller (Xinput)
| Input | Action |
| :---: | :---: |
| Left Analog -> Right | Walk Right |
| Left Analog <- Left | Walk Left |
| A | Jump |
| B | Sneak / Crouch |
| Right Trigger | Sprint / Run |

# Setup & Tweaking

If you'd like to clone this repo and run it locally, you'll need Godot 4.x.

Almost every variable in the character controller is exposed via Godot's @export variables. This means you don't need to touch the code to change the game feel.

- To make it feel heavier: Lower Ground Acceleration and raise Ground Friction.

- To make it feel more arcade-like: Raise Ground Acceleration and lower Ground Friction.

- To adjust the run-jump: Tweak Run Jump Boost for distance and Run Jump Gravity Multiplier for floatiness (lower values equal more hang time, higher values equal a snappier fall).

#  Contributing

Because this is a learning project and completely open source, you are more than welcome to use, fork, and adapt this code for your own projects.

I'm still early in my game dev journey, so I'm always open to feedback! If you spot a bug, know a better way to handle state machines, or have suggestions for improving the "game feel," feel free to open an issue or submit a pull request.
