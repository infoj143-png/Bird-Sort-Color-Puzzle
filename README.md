# Bird Sort Color Puzzle

A cute Godot 4 mobile bird sorting puzzle game.

## Features
- Cute colorful bird sorting puzzle
- Android mobile portrait game
- Branches with max 4 birds
- Tap bird, tap branch to move
- Same color sorting rule
- 4 same color birds fly away
- Level complete popup
- Restart and next level buttons
- Optimized for low-end Android (GL Compatibility renderer)

## How to Play
1. Tap a bird on a branch to select it.
2. Tap another branch to move the selected bird(s).
3. A bird can only move if:
   - The target branch is empty.
   - The top bird of the target branch has the same color.
   - The target branch has space (max 4 birds).
4. If a branch has 4 birds of the same color, they fly away!
5. Sort all birds to complete the level.

## Project Structure
- `scenes/`: Godot scenes (.tscn)
- `scripts/`: GDScript files (.gd)
- `assets/`: Placeholder for game assets (birds, UI, etc.)

## Development
This project was created using Godot 4.2.
To run the game, open `project.godot` in Godot Engine and press Play.
