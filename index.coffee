# vim: set shiftwidth=2 tabstop=2 softtabstop=2 expandtab:

ever = require 'ever'
datgui = require 'dat-gui'

ItemPile = require 'itempile'
Inventory = require 'inventory'
InventoryWindow = require 'inventory-window'
{Recipe, AmorphousRecipe, PositionalRecipe, CraftingThesaurus, RecipeLocator} = require 'craftingrecipes'

createGame = require 'voxel-engine'
createPlugins = require 'voxel-plugins'

# plugins (loaded by voxel-plugins; listed here for browserify)
require 'voxel-registry'
require 'voxel-carry'
require 'voxel-workbench'
require 'voxel-chest'
require 'voxel-inventory-hotbar'
require 'voxel-inventory-dialog'
require 'voxel-oculus'
require 'voxel-highlight'
require 'voxel-player'
require 'voxel-fly'
require 'voxel-gamemode'
require 'voxel-walk'
require 'voxel-mine'
require 'voxel-harvest'
require 'voxel-use'
require 'voxel-reach'
require 'voxel-pickaxe'
require 'voxel-blockdata'
require 'voxel-daylight'
require 'voxel-land'

require 'voxel-debug'
require 'voxel-plugins-ui'
require 'kb-bindings-ui'

module.exports = () ->
  console.log 'voxpopuli starting'

  if window.performance && window.performance.timing
    loadingTime = Date.now() - window.performance.timing.navigationStart
    console.log "User-perceived page loading time: #{loadingTime / 1000}s"

  console.log 'initializing plugins'
  plugins = createPlugins null, {require: require}

  configuration =
    'voxel-engine':
      lightsDisabled: true
      arrayType: Uint16Array
      useAtlas: false
      generateChunks: false
      chunkDistance: 2
      materials: []  # added dynamically later
      texturePath: 'AssetPacks/ProgrammerArt/textures/blocks/' # subproject with textures
      worldOrigin: [0, 0, 0]
      controls:
        discreteFire: false
        fireRate: 100 # ms between firing
        jumpTimer: 25
      keybindings:
        # voxel-engine defaults
        'W': 'forward'
        'A': 'left'
        'S': 'backward'
        'D': 'right'
        '<up>': 'forward'
        '<left>': 'left'
        '<down>': 'backward'
        '<right>': 'right'
        '<mouse 1>': 'fire'
        '<mouse 3>': 'firealt'
        '<space>': 'jump'
        '<shift>': 'crouch'
        '<control>': 'alt'
        '<tab>': 'sprint'

        # our extras
        'R': 'pov'
        'T': 'vr'
        'O': 'home'
        'E': 'inventory'
        'C': 'gamemode'
    'voxel-registry': {}
    'craftingrecipes': {}
    'voxel-carry': {inventoryWidth:10, inventoryRows:5}
    'voxel-blockdata': {}
    'voxel-chest': {}
    'voxel-workbench': {}
    'voxel-pickaxe': {}
    'voxel-daylight': {ambientColor: 0x888888, directionalColor: 0xffffff}
    'voxel-land': {populateTrees: true}
    # note: onDemand so doesn't automatically enable
    'voxel-oculus': { distortion: 0.2, separation: 0.5, onDemand: true } # TODO: switch to voxel-oculus-vr? https://github.com/vladikoff/voxel-oculus-vr?source=c - closer matches threejs example
    'voxel-player': {image: 'player.png', homePosition: [2,14,4], homeRotation: [0,0,0]}
    'voxel-fly': {flySpeed: 0.8, onDemand: true}
    'voxel-gamemode': {}
    'voxel-walk': {}
    'voxel-inventory-hotbar': {inventorySize:10}
    'voxel-inventory-dialog': {}
    'voxel-reach': { reachDistance: 8 }
    # left-click hold to mine
    'voxel-mine':
      instaMine: false
      progressTexturesPrefix: 'destroy_stage_'
      progressTexturesCount: 9
    # right-click to place block (etc.)
    'voxel-use': {}
    # handles 'break' event from voxel-mine (left-click hold breaks blocks), collects block and adds to inventory
    'voxel-harvest': {}
    # highlight blocks when you look at them
    'voxel-highlight':
      color:  0xff0000
      distance: 8,
      adjacentActive: () -> false   # don't hold <Ctrl> for block placement (right-click instead, 'reach' plugin) # TODO: not serializable, problem?

    # the GUI window (built-in toggle with 'H')
    'voxel-debug': {}
    'voxel-plugins-ui': {}
    'kb-bindings-ui': {}

  for name, opts of configuration
    plugins.add name, opts

  plugins.loadAll()

  # the game view element itself
  game = plugins.get('voxel-engine')
  window.game = window.g = game # for debugging
  game.appendTo document.body
  return game if game.notCapable()


  # load textures after all plugins loaded (since they may add their own)
  registry = plugins.get('voxel-registry')
  game.materials.load registry.getBlockPropsAll 'texture'
  global.InventoryWindow_defaultGetTexture = (itemPile) => registry.getItemPileTexture(itemPile) # TODO: cleanup

  game.buttons.down.on 'pov', () -> plugins.get('voxel-player')?.toggle()
  game.buttons.down.on 'vr', () -> plugins.toggle 'voxel-oculus'
  game.buttons.down.on 'home', () -> plugins.get('voxel-player')?.home()
  game.buttons.down.on 'inventory', () -> plugins.get('voxel-inventory-dialog')?.show()

  return game

